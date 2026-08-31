{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types;

  cfg = config.services.agent-sandbox;

  # Packages available inside the sandbox
  sandboxPackages = with pkgs;
    [
      bash
      claude-code
      coreutils
      curl
      findutils
      gawk
      git
      gnugrep
      gnused
      gnutar
      gzip
      jq
      nodejs_24
      openssh
      ripgrep
      xz
    ]
    ++ cfg.extraPackages;

  # Build a minimal NixOS root filesystem for the container
  sandboxRootfs = pkgs.runCommand "agent-sandbox-rootfs" {} ''
    mkdir -p $out/{bin,etc,tmp,nix,usr/bin,var/tmp}
    mkdir -p $out/etc/ssl/certs

    # Symlink all sandbox packages into a unified profile
    ${lib.concatMapStringsSep "\n" (pkg: ''
        for dir in bin lib share etc; do
          if [ -d "${pkg}/$dir" ]; then
            mkdir -p $out/$dir
            for f in "${pkg}/$dir"/*; do
              ln -sf "$f" "$out/$dir/" 2>/dev/null || true
            done
          fi
        done
      '')
      sandboxPackages}

    # SSL certificates for HTTPS
    ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt
    ln -sf ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt

    # Basic system files
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "agent:x:1000:1000:agent:/home/agent:/bin/bash" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "agent:x:1000:" >> $out/etc/group
    echo "nameserver 100.100.100.100" > $out/etc/resolv.conf
    echo "nameserver 1.1.1.1" >> $out/etc/resolv.conf

    # Env wrapper script
    cat > $out/bin/agent-entry <<'ENTRY'
    #!/bin/bash
    set -euo pipefail
    export HOME=/home/agent
    export PATH="/bin:/usr/bin"
    export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

    if [ -f /home/agent/.env ]; then
      set -a
      source /home/agent/.env
      set +a
    fi

    cd /workspace
    exec "$@"
    ENTRY
    chmod +x $out/bin/agent-entry
  '';

  # Script to launch a sandboxed agent run
  launchScript = pkgs.writeShellScriptBin "agent-sandbox" ''
    set -euo pipefail

    usage() {
      echo "Usage: agent-sandbox [options] <repo-url-or-path> [prompt]"
      echo ""
      echo "Options:"
      echo "  -b, --branch BRANCH    Branch to checkout"
      echo "  -n, --name NAME        Session name (default: auto-generated)"
      echo "  -p, --prompt-file FILE  Read prompt from file instead of argument"
      echo "  -k, --keep             Keep sandbox after completion"
      echo "  -h, --help             Show this help"
      exit 0
    }

    BRANCH=""
    SESSION_NAME="agent-$(date +%s)-$$"
    PROMPT_FILE=""
    KEEP=false

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -b|--branch) BRANCH="$2"; shift 2 ;;
        -n|--name) SESSION_NAME="$2"; shift 2 ;;
        -p|--prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        -k|--keep) KEEP=true; shift ;;
        -h|--help) usage ;;
        *) break ;;
      esac
    done

    REPO="''${1:?repo URL or path required}"
    PROMPT="''${2:-}"

    if [ -n "$PROMPT_FILE" ] && [ -z "$PROMPT" ]; then
      PROMPT="$(cat "$PROMPT_FILE")"
    fi

    if [ -z "$PROMPT" ]; then
      echo "Error: prompt required (as argument or via --prompt-file)"
      exit 1
    fi

    SANDBOX_BASE="${cfg.stateDirectory}/sessions/$SESSION_NAME"
    WORKSPACE="$SANDBOX_BASE/workspace"
    OVERLAY_UPPER="$SANDBOX_BASE/upper"
    OVERLAY_WORK="$SANDBOX_BASE/work"
    OVERLAY_MERGED="$SANDBOX_BASE/merged"

    mkdir -p "$WORKSPACE" "$OVERLAY_UPPER" "$OVERLAY_WORK" "$OVERLAY_MERGED"

    cleanup() {
      if [ "$KEEP" = "false" ]; then
        umount "$OVERLAY_MERGED" 2>/dev/null || true
        rm -rf "$SANDBOX_BASE"
      else
        umount "$OVERLAY_MERGED" 2>/dev/null || true
        echo "Sandbox preserved at: $SANDBOX_BASE"
        echo "Workspace: $WORKSPACE"
      fi
    }
    trap cleanup EXIT

    # Clone or copy the repo
    if [[ "$REPO" == http* ]] || [[ "$REPO" == git@* ]]; then
      echo "Cloning $REPO..."
      git clone ''${BRANCH:+--branch "$BRANCH"} --depth=1 "$REPO" "$WORKSPACE"
    elif [ -d "$REPO" ]; then
      echo "Copying $REPO..."
      cp -a "$REPO/." "$WORKSPACE/"
      if [ -n "$BRANCH" ]; then
        git -C "$WORKSPACE" checkout "$BRANCH"
      fi
    else
      echo "Error: $REPO is not a valid URL or directory"
      exit 1
    fi

    # Set up overlay filesystem for rootfs (sandbox packages are read-only)
    mount -t overlay overlay \
      -o lowerdir=${sandboxRootfs},upperdir=$OVERLAY_UPPER,workdir=$OVERLAY_WORK \
      "$OVERLAY_MERGED"

    mkdir -p "$OVERLAY_MERGED/home/agent" "$OVERLAY_MERGED/workspace"

    # Write the API key into the sandbox
    if [ -f "${cfg.apiKeyFile}" ]; then
      echo "ANTHROPIC_API_KEY=$(cat "${cfg.apiKeyFile}")" > "$OVERLAY_MERGED/home/agent/.env"
      chmod 600 "$OVERLAY_MERGED/home/agent/.env"
    fi

    echo "Starting sandboxed agent session: $SESSION_NAME"
    echo "Workspace: $WORKSPACE"
    echo "Prompt: $PROMPT"

    # Run Claude Code inside systemd-nspawn container
    systemd-nspawn \
      --quiet \
      --directory="$OVERLAY_MERGED" \
      --bind="$WORKSPACE:/workspace" \
      --bind-ro=/nix/store \
      --private-network=false \
      --user=root \
      --setenv=HOME=/home/agent \
      --setenv=PATH="/bin:/usr/bin" \
      --setenv=SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
      --setenv=NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
      --setenv=ANTHROPIC_API_KEY="$(cat "${cfg.apiKeyFile}" 2>/dev/null || echo "")" \
      /bin/claude \
        --dangerously-skip-permissions \
        --print \
        --output-format=text \
        "$PROMPT"

    echo "Agent session $SESSION_NAME completed."

    # Show what changed
    if [ -d "$WORKSPACE/.git" ]; then
      echo ""
      echo "=== Changes ==="
      git -C "$WORKSPACE" --no-pager diff --stat
    fi
  '';
in {
  options.services.agent-sandbox = {
    enable = mkEnableOption "sandboxed AI agent execution environment";

    stateDirectory = mkOption {
      type = types.path;
      default = "/var/lib/agent-sandbox";
      description = "Directory for sandbox sessions and state.";
    };

    apiKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing ANTHROPIC_API_KEY.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to make available inside sandboxes.";
    };
  };

  config = mkIf cfg.enable {
    # Ensure systemd-nspawn is available
    environment.systemPackages = [
      launchScript
      pkgs.systemd
    ];

    # Create state directory
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDirectory} 0750 root root -"
      "d ${cfg.stateDirectory}/sessions 0750 root root -"
    ];
  };
}

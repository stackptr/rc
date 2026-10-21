# Coding agents on glyph: OpenCode's server (code.zx.dev) and Paseo
# (agents.zx.dev), which runs Claude Code, OpenCode and Pi agents. Everything
# runs as one unprivileged user, and every agent process runs inside the same
# nono profile, which grants the workspaces and the agents' own state but not
# Paseo's home (its local credential and config) or anything else of glyph's.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  user = "opencode";
  home = "/var/lib/opencode";
  # Repositories the agents work on; Paseo's worktrees go in .worktrees
  workspaces = "${home}/workspaces";
  paseoHome = "/var/lib/paseo";
  opencodePort = 8890;
  paseoPort = 6767;
  # Tailnet addresses, from `tailscale ip <device>`; update them if a device
  # re-registers
  tailnet = {
    spore = {
      v4 = "100.89.150.33";
      v6 = "fd7a:115c:a1e0::a033:9621";
    };
    # The iPhone and iPad, for the Paseo app
    blip = {
      v4 = "100.82.15.58";
      v6 = "fd7a:115c:a1e0::3333:f3a";
    };
    slate = {
      v4 = "100.74.6.1";
      v6 = "fd7a:115c:a1e0::a33:601";
    };
  };
  # Drops tailnet connections to port unless they come from one of devices
  onlyFrom = devices: port:
    lib.concatMapStrings (device: ''
      iptables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -s ${tailnet.${device}.v4} -j RETURN
      ip6tables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -s ${tailnet.${device}.v6} -j RETURN
    '')
    devices
    + ''
      ip46tables -t mangle -A opencode-in -i tailscale0 -p tcp --dport ${toString port} -j DROP
    '';

  stromaModel = "Qwen3.8-27B-MTPLX-Optimized-Quality";
  stromaURL = "http://stroma.note-iwato.ts.net:8000/v1";
  json = pkgs.formats.json {};

  profile = import ../../../lib/llm-profile.nix inputs.llm-profile;
  # A shorter prompt helps a 27B model more than it helps Claude.
  context = pkgs.writeText "AGENTS.md" profile.agent;
  opencodeSettings = json.generate "opencode.json" {
    "$schema" = "https://opencode.ai/config.json";
    model = "stroma/${stromaModel}";
    small_model = "stroma/${stromaModel}";
    enabled_providers = ["stroma"];
    autoupdate = false;
    share = "disabled";
    instructions = ["${context}"];
    mcp.glyph = {
      type = "remote";
      url = "http://glyph:8090/mcp";
    };
    # oMLX on Stroma (hosts/Stroma/omlx.nix)
    provider.stroma = {
      npm = "@ai-sdk/openai-compatible";
      name = "Stroma";
      options.baseURL = stromaURL;
      # An oMLX sub-key, from opencode-env.age
      options.apiKey = "{env:STROMA_API_KEY}";
      models.${stromaModel}.name = "Qwen 3.8 27B";
    };
  };
  piModels = json.generate "models.json" {
    providers.stroma = {
      baseUrl = stromaURL;
      api = "openai-completions";
      apiKey = "$STROMA_API_KEY";
      models = [
        {
          id = stromaModel;
          name = "Qwen 3.8 27B";
        }
      ];
    };
  };
  piSettings = json.generate "settings.json" {
    defaultProvider = "stroma";
    defaultModel = stromaModel;
  };

  # nono adds its `default` profile: system paths read-only, ~/.ssh and other
  # credentials denied, workdir none. Paths not listed here, like the rest of
  # Paseo's home (its local credential and config) and of /var/lib, don't
  # exist inside the sandbox.
  nonoProfile = json.generate "agents.json" {
    meta = {
      name = "agents";
      description = "Coding agents on glyph";
    };
    groups = {
      include = ["nix_runtime" "git_config" "user_caches_linux" "claude_cache_linux"];
      # rm, mv, cp, npm, kill and so on, which agents need
      exclude = ["dangerous_commands"];
    };
    # Explicit grants only, never the working directory: Paseo starts some
    # processes in the home (probing Pi from Settings, for one), and granting
    # that would cover ~/.ssh and the rest, which Landlock can't then deny, so
    # nono refuses to start. A process whose directory isn't granted starts in /.
    filesystem = {
      read = [
        "/etc"
        # Paseo writes its OpenCode bridge plugins here, and the OpenCode
        # server it starts has to load them; read-only, so agents can't
        # change what Paseo's server runs
        "${paseoHome}/runtime/opencode"
      ];
      allow = [
        # Repositories and Paseo's worktrees, where agents work
        workspaces
        # The working directory of the OpenCode server Paseo starts
        "${paseoHome}/opencode-home"
        "${home}/.config/opencode"
        "${home}/.local/share/opencode"
        "${home}/.local/state/opencode"
        "${home}/.claude"
        "${home}/.pi/agent"
      ];
    };
    # The daemon's password would let an agent drive Paseo itself
    environment.deny_vars = ["PASEO_PASSWORD"];
  };
  # No audit trail: nono would keep it in ~/.local/state/nono, where nothing
  # reads it, and failing to create it there stops the agent from starting.
  # The journal has each unit's output.
  nonoRun = "${lib.getExe pkgs.nono} -s run --profile agents --no-audit --";
  # Agents can write to their own config directories (the sandbox has to
  # grant them, and Landlock can't make files inside a granted directory
  # read-only), so one could plant instructions or code for every later
  # session: a CLAUDE.md, a skill, a hook, an MCP server, a Pi extension.
  # Unlike a repo's own AGENTS.md or .claude/, nothing would show it in a
  # diff. Before every launch, outside the sandbox, relink what
  # home-manager manages and remove the other places they read from.
  hm = config.home-manager.users.${user};
  managed = prefix:
    map (file: file.target)
    (lib.filter (file: file.enable && lib.hasPrefix prefix file.target) (lib.attrValues hm.home.file));
  resetAgentConfig = pkgs.writeShellScript "reset-agent-config" ''
    set -eu
    cd ${home}
    for target in ${lib.escapeShellArgs (managed ".claude/" ++ managed ".pi/agent/")}; do
      mkdir -p "$(dirname "$target")"
      [ -L "$target" ] || rm -rf "$target"
      ln -sfnT "${hm.home-files}/$target" "$target"
    done
    for entry in .claude/skills/* .claude/skills/.[!.]*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      case " ${toString (managed ".claude/skills/")} " in
        *" $entry "*) ;;
        *) rm -rf "$entry" ;;
      esac
    done
    rm -rf .claude/agents .claude/commands .claude/hooks .claude/plugins .claude/output-styles
    rm -rf .pi/agent/extensions .pi/agent/skills .pi/agent/prompts .pi/agent/themes
    rm -f .pi/agent/AGENTS.override.md .pi/agent/AGENTS.MD .pi/agent/CLAUDE.md .pi/agent/CLAUDE.MD \
      .pi/agent/SYSTEM.md .pi/agent/APPEND_SYSTEM.md .pi/agent/mcp.json
    # OpenCode's settings come from OPENCODE_CONFIG, so its global config
    # directory holds nothing of ours
    mkdir -p .config/opencode
    find .config/opencode -mindepth 1 -delete
    # Claude keeps user- and local-scope MCP servers in its state file;
    # only the gateway, from home-manager, and Paseo's own should exist
    state=.claude/.claude.json
    filter='del(.mcpServers) | if .projects then .projects |= map_values(del(.mcpServers)) else . end'
    if [ -f "$state" ] && ! ${lib.getExe pkgs.jq} -e "($filter) == ." "$state" >/dev/null; then
      ${lib.getExe pkgs.jq} "$filter" "$state" > "$state.reset"
      mv "$state.reset" "$state"
    fi
  '';
  # Paseo launches each provider through these, so every agent it starts is
  # sandboxed. Workers don't get Claude's token.
  sandboxed = name: command:
    pkgs.writeShellScript "${name}-sandboxed" ''
      ${resetAgentConfig}
      exec ${nonoRun} ${command} "$@"
    '';
  claudeSandboxed = sandboxed "claude" (lib.getExe pkgs.claude-code);
  opencodeSandboxed = sandboxed "opencode" "env -u CLAUDE_CODE_OAUTH_TOKEN ${lib.getExe pkgs.opencode}";
  piSandboxed = sandboxed "pi" "env -u CLAUDE_CODE_OAUTH_TOKEN ${lib.getExe pkgs.pi-coding-agent}";

  paseoConfig = json.generate "paseo-config.json" {
    "$schema" = "https://paseo.sh/schemas/paseo.config.v1.json";
    version = 1;
    daemon = {
      listen = "0.0.0.0:${toString paseoPort}";
      hostnames = ["agents.zx.dev" "glyph" "glyph.note-iwato.ts.net"];
      # Whose X-Forwarded-* headers to believe: spore's nginx, on either
      # address family. Paseo derives the web UI's ws:// or wss:// from
      # X-Forwarded-Proto, so a spore connection over IPv6 that isn't listed
      # here gets ws://, which the browser blocks on https://agents.zx.dev.
      trustedProxies = ["loopback" tailnet.spore.v4 tailnet.spore.v6];
      relay.enabled = false;
      # Paseo's tools (launching and messaging agents) for the supervisor
      mcp = {
        enabled = true;
        injectIntoAgents = true;
      };
    };
    worktrees.root = "${workspaces}/.worktrees";
    features.webUi.enabled = true;
    log.console = {
      level = "info";
      format = "json";
    };
    agents.providers = {
      # The supervisor: plans, delegates and reviews
      claude.command = ["${claudeSandboxed}"];
      # Workers, on oMLX: they get no Paseo tools, so they can't launch agents
      opencode = {
        command = ["${opencodeSandboxed}"];
        paseoTools.enabled = false;
      };
      pi = {
        command = ["${piSandboxed}"];
        paseoTools.enabled = false;
      };
      codex.enabled = false;
      omp.enabled = false;
    };
  };

  hardening = {
    User = user;
    Group = user;
    Slice = "agents.slice";
    Restart = "always";
    RestartSec = 5;
    ProtectSystem = "strict";
    ProtectHome = true;
    ReadWritePaths = [home];
    # EnvironmentFile is read by systemd before the namespace is set up.
    # Postgres trusts every local connection (db.nix): see the firewall below.
    InaccessiblePaths = ["/mnt" "/run/agenix" "/run/agenix.d" "/run/postgresql"];
    PrivateTmp = true;
    PrivateDevices = true;
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
    # Bun's JIT needs writable executable memory, so no MemoryDenyWriteExecute
  };
  # procps for ps: Paseo lists an OpenCode server's children with
  # `ps --ppid` when it stops one, and an ENOENT there crashes its worker
  path = with pkgs; [bash coreutils findutils gnugrep gnused git procps];
  # Give up after 5 failed starts in 5 minutes instead of looping, so the
  # "Systemd unit failed" alert fires rather than only the restart one
  startLimit = {
    startLimitIntervalSec = 300;
    startLimitBurst = 5;
  };
in {
  # STROMA_API_KEY
  age.secrets.opencode-env = {
    file = ../secrets/opencode-env.age;
    owner = user;
  };
  # PASEO_PASSWORD, for the web UI and every other client. Unlike OpenCode's
  # server, Paseo needs one even behind the firewall rule below: without it,
  # anything reaching its port controls it, and agents reach it on loopback.
  age.secrets.paseo-env = {
    file = ../secrets/paseo-env.age;
    owner = user;
  };
  # CLAUDE_CODE_OAUTH_TOKEN from `claude setup-token`, so Claude Code agents
  # use the Claude subscription. ANTHROPIC_API_KEY would take precedence and
  # bill the API instead, so don't add it.
  age.secrets.claude-code-env = {
    file = ../secrets/claude-code-env.age;
    owner = user;
  };

  # Agents run shell commands as this user, so it gets none of mu's access:
  # no /home (mu's SSH config and keys), no /mnt pools, no other secrets
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    inherit home;
  };
  users.groups.${user} = {};

  # Only spore's nginx may reach OpenCode's server or Paseo over the
  # tailnet, which puts Pocket ID in front of them (code.zx.dev,
  # agents.zx.dev). The exception is Paseo from the iPhone and iPad: its app
  # can't log in to Pocket ID, so it connects directly with only Paseo's
  # password, and any device listed here can drive the agents. This can't
  # go in nixos-fw: tailscaled's ts-input chain,
  # first in filter INPUT, accepts everything from tailscale0 before nixos-fw
  # sees it. mangle INPUT runs earlier and tailscaled leaves it alone; it
  # can't REJECT, so others time out.
  #
  # Postgres trusts every local connection (hosts/glyph/services/db.nix), so
  # anything running as this user could connect as the superuser. The socket
  # is hidden from the units; the opencode-out chain rejects TCP to 5432 on
  # any address.
  networking.firewall.extraCommands = ''
    ip46tables -t mangle -N opencode-in 2>/dev/null || ip46tables -t mangle -F opencode-in
    ${onlyFrom ["spore"] opencodePort}${onlyFrom ["spore" "blip" "slate"] paseoPort}
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -I INPUT -j opencode-in

    ip46tables -N opencode-out 2>/dev/null || ip46tables -F opencode-out
    ip46tables -A opencode-out -p tcp --dport 5432 -j REJECT
    ip46tables -D OUTPUT -m owner --uid-owner ${user} -j opencode-out 2>/dev/null || true
    ip46tables -I OUTPUT -m owner --uid-owner ${user} -j opencode-out
  '';
  networking.firewall.extraStopCommands = ''
    ip46tables -t mangle -D INPUT -j opencode-in 2>/dev/null || true
    ip46tables -t mangle -F opencode-in 2>/dev/null || true
    ip46tables -t mangle -X opencode-in 2>/dev/null || true
    ip46tables -D OUTPUT -m owner --uid-owner ${user} -j opencode-out 2>/dev/null || true
    ip46tables -F opencode-out 2>/dev/null || true
    ip46tables -X opencode-out 2>/dev/null || true
  '';

  # One budget for every agent, so they can't starve glyph's other services
  systemd.slices.agents.sliceConfig = {
    MemoryMax = "16G";
    CPUQuota = "800%";
  };

  systemd.tmpfiles.settings.agents = let
    dir = {
      d = {
        inherit user;
        group = user;
        mode = "0700";
      };
    };
    link = target: {"L+".argument = "${target}";};
  in {
    # The home predates these units: an earlier DynamicUser unit left it,
    # and systemd moved it into place, owned by nobody (65534), so neither
    # OpenCode nor nono could write to it. Everything in it belongs to the
    # agent user, so Z resets ownership recursively; modes are left alone.
    ${home} =
      dir
      // {
        Z = {
          inherit user;
          group = user;
          mode = "-";
        };
      };
    ${workspaces} = dir;
    "${home}/.config" = dir;
    "${home}/.config/opencode" = dir;
    "${home}/.config/nono" = dir;
    "${home}/.config/nono/profiles" = dir;
    "${home}/.config/nono/profiles/agents.json" = link nonoProfile;
    # The profile grants OpenCode's data and state directories, so they have
    # to exist and be the agent user's before the first start
    "${home}/.local" = dir;
    "${home}/.local/share" = dir;
    "${home}/.local/share/opencode" = dir;
    "${home}/.local/state" = dir;
    "${home}/.local/state/opencode" = dir;
    "${home}/.claude" = dir;
    "${home}/.pi" = dir;
    "${home}/.pi/agent" = dir;
    ${paseoHome} = dir;
    # Granted by the nono profile, so it has to exist before Paseo first runs
    "${paseoHome}/opencode-home" = dir;
    "${paseoHome}/runtime" = dir;
    "${paseoHome}/runtime/opencode" = dir;
    "${paseoHome}/config.json" = link paseoConfig;
  };

  # code.zx.dev on spore proxies here
  systemd.services.opencode-web = {
    description = "OpenCode server";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service"];
    inherit (startLimit) startLimitIntervalSec startLimitBurst;
    inherit path;
    environment = {
      HOME = home;
      OPENCODE_CONFIG = opencodeSettings;
    };
    serviceConfig =
      hardening
      // {
        ExecStartPre = resetAgentConfig;
        ExecStart = "${nonoRun} ${lib.getExe pkgs.opencode} serve --port ${toString opencodePort} --hostname 0.0.0.0";
        EnvironmentFile = config.age.secrets.opencode-env.path;
        StateDirectory = "opencode";
        StateDirectoryMode = "0700";
        WorkingDirectory = workspaces;
      };
  };

  # Paseo runs Claude Code with this user's config (CLAUDE_CONFIG_DIR is
  # ~/.claude), so it uses the same module as my own Claude Code
  # (modules/home/development.nix): the llm-profile prompt, the glyph MCP
  # gateway, llm-profile's skills, the read-only permission allowlist and
  # telemetry. They follow llm-profile and Paseo updates with the flake.
  # resetAgentConfig restores these before every launch.
  home-manager.users.${user} = {
    imports = [../../../modules/home/development.nix];
    home.stateVersion = "23.11";
    rc.development.ai.enable = true;
    programs.claude-code = {
      # Paseo runs pkgs.claude-code itself, through the nono wrapper
      package = null;
      # Paseo's orchestration skills, from the source of the Paseo it runs.
      # The nixpkgs package leaves out the skills/ directory its own
      # installer copies from, so Settings > Agents > Orchestration skills
      # can't install them.
      skills =
        lib.genAttrs ["paseo" "paseo-handoff" "paseo-committee" "paseo-advisor"]
        (name: "${pkgs.paseo.src}/skills/${name}");
    };
    # Pi's endpoint, default model and instructions. It has no MCP gateway,
    # so it gets the standalone prompt. force: tmpfiles linked the first
    # two before home-manager managed them.
    home.file = {
      ".pi/agent/models.json" = {
        source = piModels;
        force = true;
      };
      ".pi/agent/settings.json" = {
        source = piSettings;
        force = true;
      };
      ".pi/agent/AGENTS.md".text = profile."agent-standalone";
    };
  };

  # agents.zx.dev on spore proxies here. Its web UI loads without the
  # password; the API and WebSocket need it.
  systemd.services.paseo = {
    description = "Paseo agent daemon";
    wantedBy = ["multi-user.target"];
    # Claude's config above, written by home-manager's activation unit
    wants = ["network-online.target" "home-manager-${user}.service"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service" "systemd-tmpfiles-resetup.service" "home-manager-${user}.service"];
    inherit (startLimit) startLimitIntervalSec startLimitBurst;
    path = path ++ [pkgs.paseo];
    environment = {
      HOME = home;
      PASEO_HOME = paseoHome;
      # Read by the OpenCode server Paseo starts
      OPENCODE_CONFIG = opencodeSettings;
      # Keeps .claude.json inside ~/.claude, which the sandbox grants
      CLAUDE_CONFIG_DIR = "${home}/.claude";
      DISABLE_AUTOUPDATER = "1";
    };
    serviceConfig =
      hardening
      // {
        ExecStart = "${pkgs.paseo}/bin/paseo-server";
        EnvironmentFile = [
          config.age.secrets.opencode-env.path
          config.age.secrets.paseo-env.path
          config.age.secrets.claude-code-env.path
        ];
        StateDirectory = ["opencode" "paseo"];
        StateDirectoryMode = "0700";
        ReadWritePaths = [home paseoHome];
        WorkingDirectory = workspaces;
        # Agents get SIGTERM with the daemon; its own shutdown takes up to 10s
        TimeoutStopSec = 15;
      };
  };
}

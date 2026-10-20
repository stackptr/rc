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
  # spore's tailnet addresses, from `tailscale ip spore`
  spore = "100.89.150.33";
  spore6 = "fd7a:115c:a1e0::a033:9621";
  onlyFromSpore = port: ''
    iptables -I nixos-fw 1 -i tailscale0 -p tcp --dport ${toString port} ! -s ${spore} -j REJECT --reject-with tcp-reset
    ip6tables -I nixos-fw 1 -i tailscale0 -p tcp --dport ${toString port} ! -s ${spore6} -j REJECT --reject-with tcp-reset
  '';

  stromaModel = "Qwen3.8-27B-MTPLX-Optimized-Quality";
  stromaURL = "http://stroma.note-iwato.ts.net:8000/v1";
  json = pkgs.formats.json {};

  # A shorter prompt helps a 27B model more than it helps Claude.
  context = pkgs.writeText "AGENTS.md" (import ../../../lib/llm-profile.nix inputs.llm-profile).agent;
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
  # credentials denied, workdir none. Paths not listed here, like Paseo's
  # home and the rest of /var/lib, don't exist inside the sandbox.
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
    # The agent's working directory: a worktree, or OpenCode's server home
    workdir.access = "readwrite";
    filesystem = {
      read = ["/etc"];
      allow = [
        workspaces
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
  # Paseo launches each provider through these, so every agent it starts is
  # sandboxed. Workers don't get Claude's token.
  sandboxed = name: command:
    pkgs.writeShellScript "${name}-sandboxed" ''
      exec ${lib.getExe pkgs.nono} -s run --profile agents --allow-cwd -- ${command} "$@"
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
      # spore's nginx, for X-Forwarded-Proto
      trustedProxies = ["loopback" "100.64.0.0/10"];
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
  path = with pkgs; [bash coreutils findutils gnugrep gnused git];
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

  # tailscale0 is trusted, so without the first rules any tailnet device
  # could use OpenCode's server or Paseo directly. Only spore's nginx may,
  # which puts Pocket ID in front of them (code.zx.dev, agents.zx.dev).
  # Others get a reset rather than a drop, so they fail at once.
  #
  # Postgres trusts every local connection (hosts/glyph/services/db.nix), so
  # anything running as this user could connect as the superuser. The socket
  # is hidden from the units; the opencode-out chain rejects TCP to 5432 on
  # any address.
  networking.firewall.extraCommands = ''
    ${onlyFromSpore opencodePort}${onlyFromSpore paseoPort}
    ip46tables -N opencode-out 2>/dev/null || ip46tables -F opencode-out
    ip46tables -A opencode-out -p tcp --dport 5432 -j REJECT
    ip46tables -D OUTPUT -m owner --uid-owner ${user} -j opencode-out 2>/dev/null || true
    ip46tables -I OUTPUT -m owner --uid-owner ${user} -j opencode-out
  '';
  networking.firewall.extraStopCommands = ''
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
    ${home} = dir;
    ${workspaces} = dir;
    "${home}/.config" = dir;
    "${home}/.config/opencode" = dir;
    "${home}/.config/nono" = dir;
    "${home}/.config/nono/profiles" = dir;
    "${home}/.config/nono/profiles/agents.json" = link nonoProfile;
    "${home}/.claude" = dir;
    "${home}/.pi" = dir;
    "${home}/.pi/agent" = dir;
    "${home}/.pi/agent/models.json" = link piModels;
    "${home}/.pi/agent/settings.json" = link piSettings;
    ${paseoHome} = dir;
    "${paseoHome}/config.json" = link paseoConfig;
  };

  # code.zx.dev on spore proxies here
  systemd.services.opencode-web = {
    description = "OpenCode server";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service"];
    inherit path;
    environment = {
      HOME = home;
      OPENCODE_CONFIG = opencodeSettings;
    };
    serviceConfig =
      hardening
      // {
        ExecStart = "${lib.getExe pkgs.nono} -s run --profile agents --allow-cwd -- ${lib.getExe pkgs.opencode} serve --port ${toString opencodePort} --hostname 0.0.0.0";
        EnvironmentFile = config.age.secrets.opencode-env.path;
        StateDirectory = "opencode";
        StateDirectoryMode = "0700";
        WorkingDirectory = workspaces;
      };
  };

  # agents.zx.dev on spore proxies here. Its web UI loads without the
  # password; the API and WebSocket need it.
  systemd.services.paseo = {
    description = "Paseo agent daemon";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target" "systemd-tmpfiles-setup.service"];
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

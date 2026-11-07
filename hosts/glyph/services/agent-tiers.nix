# Capability tiers for unattended agent jobs. Paseo (./agents.nix) runs
# every agent as one user, `opencode`, with the write tier's access: GitHub
# pushes, the agents' MCP group, the network. Jobs that need less run as a
# tier's own user instead, each with its own home, nono profile, MCP group
# and an egress chain that allows only the tier's MCP proxy and oMLX:
#
# - observe: alert investigation, log sweeps. Grafana's read tools and
#   rc-source.
# - review: PR review. rc-source; the dispatcher passes the diff in.
#
# They don't run under Paseo: Paseo starts every agent as its own user and
# can't switch, so a tier would need a daemon of its own (user, port,
# password, firewall exception), only to show unattended runs nobody
# watches. Jobs run as transient systemd units through `agent-run <tier>
# <command>` instead, e.g. `agent-run observe opencode run --standalone
# "<prompt>"`, and the dispatcher (#740) keeps the record of each run.
{
  config,
  lib,
  pkgs,
  ...
}: let
  common = import ./agents-common.nix;
  tailnet = import ../tailnet.nix;
  mcpjunglePort = config.services.mcpjungle.port;
  json = pkgs.formats.json {};

  # Read-only tools only. Listed rather than whole servers, so a tool a
  # server adds later isn't the tiers' until it's added here.
  grafanaReadTools = map (tool: "grafana__${tool}") [
    "list_datasources"
    "query_prometheus"
    "query_prometheus_histogram"
    "list_prometheus_metric_names"
    "list_prometheus_label_names"
    "list_prometheus_label_values"
    "query_loki_logs"
    "query_loki_patterns"
    "query_loki_stats"
    "list_loki_label_names"
    "list_loki_label_values"
    "search_dashboards"
    "get_dashboard_summary"
    "get_dashboard_panel_queries"
    "get_annotations"
    "alerting_rules_read"
  ];
  rcSourceTools = map (tool: "rc-source__${tool}") [
    "directory_tree"
    "list_directory"
    "read_text_file"
    "read_multiple_files"
    "search_files"
  ];

  tiers = {
    observe = {
      description = "Observe tier: alert investigation and log sweeps";
      mcpPort = 8093;
      tools = grafanaReadTools ++ rcSourceTools;
      note = ''
        You can read Loki logs, Prometheus metrics, dashboards and alert rules through the `glyph` MCP server's grafana tools, and the configuration of the user's hosts (github.com/stackptr/rc) through its rc-source tools.
      '';
    };
    review = {
      description = "Review tier: PR review";
      mcpPort = 8094;
      tools = rcSourceTools;
      note = ''
        You can read the configuration of the user's hosts (github.com/stackptr/rc), as last deployed, through the `glyph` MCP server's rc-source tools. The change you review is in your prompt.
      '';
    };
  };

  # OpenCode's `run --standalone` starts its server as a child on a random
  # loopback port and talks to it over HTTP, so the tiers may reach loopback
  # ports in Linux's default ephemeral range (net.ipv4.ip_local_port_range).
  # glyph's fixed services listen below it.
  ephemeralPorts = "32768:60999";

  tierConfig = name: tier: let
    user = "agent-${name}";
    home = "/var/lib/${user}";
    group = "agents-${name}";
    mcpPath = "/v0/groups/${group}/mcp";

    context = pkgs.writeText "AGENTS.md" ''
      You run unattended, as the ${name} tier of the user's agent jobs on glyph. There's no one to answer questions: do what the prompt asks with the tools you have, and return only what it asks for. If you can't, say what you checked and what's missing rather than guessing.

      You can't run shell commands, edit files or reach the internet. ${tier.note}
    '';
    opencodeConfig = json.generate "opencode-${name}.json" {
      "$schema" = "https://opencode.ai/config.json";
      model = "stroma/${common.stromaModel}";
      small_model = "stroma/${common.stromaModel}";
      enabled_providers = ["stroma"];
      autoupdate = false;
      share = "disabled";
      instructions = ["${context}"];
      mcp.glyph = {
        type = "remote";
        url = "http://127.0.0.1:${toString tier.mcpPort}${mcpPath}";
      };
      # By address, so the tiers need no DNS: a resolver that forwards
      # anywhere would be a way out
      provider.stroma = {
        npm = "@ai-sdk/openai-compatible";
        name = "Stroma";
        options.baseURL = "http://${tailnet.stroma.v4}:${toString common.stromaPort}/v1";
        options.apiKey = "{env:STROMA_API_KEY}";
        models.${common.stromaModel}.name = "Qwen 3.8 27B";
      };
      # Last match wins, and attribute names are sorted, so "*" comes first.
      # The egress chain and nono enforce the same; these keep the model
      # from trying.
      permission = {
        "*" = "allow";
        bash = "deny";
        edit = "deny";
        webfetch = "deny";
        websearch = "deny";
      };
    };
    # No working directory or repository: OpenCode's state, and /tmp, which
    # is the unit's own (PrivateTmp) and gone after the run
    nonoProfile = json.generate "${user}.json" {
      meta = {
        name = user;
        inherit (tier) description;
      };
      groups.include = ["nix_runtime" "user_caches_linux" "linux_temp_read"];
      filesystem = {
        read = ["/etc"];
        allow = [
          "${home}/.config/opencode"
          "${home}/.local/share/opencode"
          "${home}/.local/state/opencode"
        ];
      };
    };
    path = with pkgs; [opencode bash coreutils curl];
    environment = {
      HOME = home;
      SHELL = lib.getExe pkgs.bash;
      PATH = lib.makeBinPath path;
      OPENCODE_CONFIG = opencodeConfig;
      # Startup fetches from models.dev, which the egress chain rejects
      OPENCODE_DISABLE_MODELS_FETCH = "1";
      OPENCODE_DISABLE_AUTOUPDATE = "1";
      # Only the config above: none from the working directory, ~/.claude
      # or Claude Code's skills
      OPENCODE_DISABLE_PROJECT_CONFIG = "1";
      OPENCODE_DISABLE_CLAUDE_CODE = "1";
    };
    properties =
      common.serviceConfig
      // {
        ReadWritePaths = [home];
        # STROMA_API_KEY; systemd reads it as root before switching user
        EnvironmentFile = config.age.secrets.opencode-env.path;
        WorkingDirectory = "/tmp";
      };
    propertyValue = value:
      if builtins.isList value
      then lib.concatStringsSep " " value
      else if builtins.isBool value
      then lib.boolToString value
      else toString value;
  in {
    inherit user home group mcpPath nonoProfile;
    runArgs = lib.concatStringsSep " " (
      [
        "--slice=agents.slice"
        "--uid=${user}"
        "--gid=${user}"
        "--description=${lib.escapeShellArg "Agent job (${name} tier)"}"
      ]
      ++ lib.mapAttrsToList (k: v: "-p ${lib.escapeShellArg "${k}=${propertyValue v}"}") properties
      ++ lib.mapAttrsToList (k: v: "--setenv=${lib.escapeShellArg "${k}=${v}"}") environment
      ++ ["-- ${lib.getExe pkgs.nono} -s run --profile ${user} --no-audit --"]
    );
    # Allowed: the tier's MCP proxy, OpenCode's own server on loopback and
    # oMLX on Stroma, by address. Everything else, DNS included, is rejected.
    firewall = ''
      ip46tables -N ${user}-out 2>/dev/null || ip46tables -F ${user}-out
      iptables -A ${user}-out -o lo -p tcp -d 127.0.0.1 --dport ${toString tier.mcpPort} -j RETURN
      iptables -A ${user}-out -o lo -p tcp -d 127.0.0.1 --dport ${ephemeralPorts} -j RETURN
      ip6tables -A ${user}-out -o lo -p tcp -d ::1 --dport ${ephemeralPorts} -j RETURN
      iptables -A ${user}-out -p tcp -d ${tailnet.stroma.v4} --dport ${toString common.stromaPort} -j RETURN
      ip46tables -A ${user}-out -j REJECT
      ip46tables -D OUTPUT -m owner --uid-owner ${user} -j ${user}-out 2>/dev/null || true
      ip46tables -I OUTPUT -m owner --uid-owner ${user} -j ${user}-out
    '';
    firewallStop = ''
      ip46tables -D OUTPUT -m owner --uid-owner ${user} -j ${user}-out 2>/dev/null || true
      ip46tables -F ${user}-out 2>/dev/null || true
      ip46tables -X ${user}-out 2>/dev/null || true
    '';
  };
  cfgs = lib.mapAttrs tierConfig tiers;

  agentRun = pkgs.writeShellScriptBin "agent-run" ''
    set -euo pipefail
    usage() {
      echo "usage: agent-run <${lib.concatStringsSep "|" (lib.attrNames cfgs)}> <command> [args...]" >&2
      exit 64
    }
    [ $# -ge 2 ] || usage
    [ "$(id -u)" = 0 ] || { echo "agent-run: must run as root" >&2; exit 77; }
    tier=$1
    shift
    # --wait and --pipe: the caller gets the job's output and exit status
    case "$tier" in
    ${lib.concatStrings (lib.mapAttrsToList (name: cfg: ''
        ${name})
          exec ${config.systemd.package}/bin/systemd-run --quiet --wait --pipe --collect \
            ${cfg.runArgs} "$@"
          ;;
      '')
      cfgs)}
    *) usage ;;
    esac
  '';
in {
  users.users = lib.mapAttrs' (_: cfg:
    lib.nameValuePair cfg.user {
      isSystemUser = true;
      group = cfg.user;
      inherit (cfg) home;
    })
  cfgs;
  users.groups = lib.mapAttrs' (_: cfg: lib.nameValuePair cfg.user {}) cfgs;

  systemd.tmpfiles.settings.agent-tiers = lib.mkMerge (lib.mapAttrsToList (_: cfg: let
    dir = {
      d = {
        inherit (cfg) user;
        group = cfg.user;
        mode = "0700";
      };
    };
  in
    lib.genAttrs [
      cfg.home
      "${cfg.home}/.config"
      "${cfg.home}/.config/nono"
      "${cfg.home}/.config/nono/profiles"
      # Granted by the nono profile, so they have to exist first
      "${cfg.home}/.config/opencode"
      "${cfg.home}/.local"
      "${cfg.home}/.local/share"
      "${cfg.home}/.local/share/opencode"
      "${cfg.home}/.local/state"
      "${cfg.home}/.local/state/opencode"
    ] (_: dir)
    // {"${cfg.home}/.config/nono/profiles/${cfg.user}.json"."L+".argument = "${cfg.nonoProfile}";})
  cfgs);

  networking.firewall.extraCommands = lib.concatMapStrings (cfg: cfg.firewall) (lib.attrValues cfgs);
  networking.firewall.extraStopCommands = lib.concatMapStrings (cfg: cfg.firewallStop) (lib.attrValues cfgs);

  # A group per tier, served to it by a loopback proxy as ./agents.nix does
  # for the write tier's
  services.mcpjungle.groups = lib.mapAttrs' (name: cfg:
    lib.nameValuePair cfg.group {
      inherit (tiers.${name}) description;
      includedTools = tiers.${name}.tools;
    })
  cfgs;
  services.nginx = {
    enable = true;
    virtualHosts = lib.mapAttrs' (name: cfg:
      lib.nameValuePair "mcp-${cfg.user}" {
        listen = [
          {
            addr = "127.0.0.1";
            port = tiers.${name}.mcpPort;
          }
        ];
        locations."= ${cfg.mcpPath}" = {
          proxyPass = "http://127.0.0.1:${toString mcpjunglePort}${cfg.mcpPath}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_buffering off;
            proxy_read_timeout 1h;
          '';
        };
        locations."/".return = "404";
      })
    cfgs;
  };

  environment.systemPackages = [agentRun];
}

{
  config,
  hostname,
  lib,
  llm-profile,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.development;
  profile = import ../../lib/llm-profile.nix llm-profile;
in {
  options = {
    rc.development = {
      ai = {
        enable = lib.mkEnableOption "tools using LLMs";

        gateway.enable = mkOption {
          default = true;
          example = false;
          description = ''
            Whether this host can reach the MCP gateway on glyph. Disable on
            hosts where MCP servers are managed elsewhere (e.g. by an
            employer) and glyph isn't reachable.
          '';
          type = lib.types.bool;
        };

        telemetry.enable = mkOption {
          default = cfg.ai.gateway.enable;
          defaultText = lib.literalExpression "config.rc.development.ai.gateway.enable";
          example = false;
          description = ''
            Whether Claude Code sends OpenTelemetry metrics to Prometheus and
            events to Loki on glyph. Prompt and response text stay redacted.
          '';
          type = lib.types.bool;
        };
      };

      containers = {
        enable = lib.mkEnableOption "container-related tooling";
      };

      javascript = {
        enable = lib.mkEnableOption "JavaScript development tooling";
      };
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.ai.enable {
      programs.zsh.sessionVariables = {
        # Disable claude-pace API fallback; rate limits come from stdin on CC >= 2.1.80
        CLAUDE_PACE_API_FALLBACK = "0";
      };

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        context =
          if cfg.ai.gateway.enable
          then profile.agent
          else profile."agent-standalone";
        # propose-rule is currently the only skill. Its fallback (leaving a
        # note in Basic Memory for a later session) needs the gateway, and
        # on a work machine, proposed rule changes shouldn't go to a public
        # repo anyway — so skip skills entirely when the gateway is disabled.
        # One entry per skill, rather than the directory, so other configs
        # can add their own (Paseo's agents on glyph, hosts/glyph/services/agents.nix)
        skills = lib.optionalAttrs cfg.ai.gateway.enable (
          lib.mapAttrs (name: _: "${profile.skills}/${name}")
          (lib.filterAttrs (_: type: type == "directory") (builtins.readDir profile.skills))
        );
        settings = {
          model = "sonnet";
          # Disabled in favor of Basic Memory MCP for cross-device access
          autoMemoryEnabled = false;
          env =
            {
              # Skip GPG signing for agent commits (it needs user interaction)
              GIT_CONFIG_COUNT = "1";
              GIT_CONFIG_KEY_0 = "commit.gpgsign";
              GIT_CONFIG_VALUE_0 = "false";
            }
            // lib.optionalAttrs cfg.ai.telemetry.enable {
              CLAUDE_CODE_ENABLE_TELEMETRY = "1";
              OTEL_METRICS_EXPORTER = "otlp";
              OTEL_LOGS_EXPORTER = "otlp";
              OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
              OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = "http://glyph.note-iwato.ts.net:9099/api/v1/otlp/v1/metrics";
              OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = "http://glyph.note-iwato.ts.net:3100/otlp/v1/logs";
              # Prometheus's OTLP receiver rejects delta temporality, Claude
              # Code's default.
              OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "cumulative";
              # Becomes a host label on metrics and an indexed label in Loki,
              # matching the other hosts' {host="..."}.
              OTEL_RESOURCE_ATTRIBUTES = "host=${lib.toLower hostname}";
            };
          statusLine = {
            type = "command";
            command = "${pkgs.claude-pace}/bin/claude-pace";
          };
          permissions = {
            allow = [
              # Nix store (read-only access for inspecting derivations and build outputs)
              "Read(/nix/store/*)"
              # File exploration
              "Bash(cat *)"
              "Bash(cut *)"
              "Bash(diff *)"
              "Bash(du *)"
              "Bash(echo *)"
              "Bash(file *)"
              "Bash(find * -name *)"
              "Bash(find * -type *)"
              "Bash(find * -path *)"
              "Bash(grep *)"
              "Bash(head *)"
              "Bash(jq *)"
              "Bash(ls *)"
              "Bash(readlink *)"
              "Bash(realpath *)"
              "Bash(rg *)"
              "Bash(sort *)"
              "Bash(tail *)"
              "Bash(tr *)"
              "Bash(uniq *)"
              "Bash(wc *)"
              "Bash(which *)"
              # Environment
              "Bash(env)"
              "Bash(hostname)"
              "Bash(printenv *)"
              "Bash(pwd)"
              "Bash(whoami)"
              # Networking
              "Bash(dig *)"
              "Bash(nslookup *)"
              "Bash(ping -c *)"
              # Nix
              "Bash(nix build *)"
              "Bash(nix develop *)"
              "Bash(nix eval *)"
              "Bash(nix flake *)"
              "Bash(nix fmt *)"
              "Bash(nix log *)"
              "Bash(nix path-info *)"
              "Bash(nix profile list*)"
              "Bash(nix registry list*)"
              "Bash(nix search *)"
              "Bash(nix show-derivation *)"
              "Bash(nix store *)"
              "Bash(nix why-depends *)"
              "Bash(nix-flake *)"
              "Bash(nixpkgs-eval *)"
              "Bash(nixpkgs-run *)"
              "Bash(nixpkgs-shell *)"
              # Git
              "Bash(git add *)"
              "Bash(git blame *)"
              "Bash(git branch *)"
              "Bash(git diff *)"
              "Bash(git log *)"
              "Bash(git remote -v*)"
              "Bash(git remote show *)"
              "Bash(git show *)"
              "Bash(git stash list*)"
              "Bash(git status)"
              "Bash(git tag -l *)"
              "Bash(git tag --list *)"
              # GitHub CLI
              "Bash(gh api:*)"
              "Bash(gh issue list*)"
              "Bash(gh issue status*)"
              "Bash(gh issue view*)"
              "Bash(gh pr checks*)"
              "Bash(gh pr diff*)"
              "Bash(gh pr list*)"
              "Bash(gh pr status*)"
              "Bash(gh pr view*)"
              "Bash(gh release list*)"
              "Bash(gh release view*)"
              "Bash(gh repo view*)"
              "Bash(gh run list*)"
              "Bash(gh run view*)"
              "Bash(gh search:*)"
              # System
              "Bash(journalctl *)"
              "Bash(mkdir *)"
              "Bash(systemctl cat *)"
              "Bash(systemctl is-active *)"
              "Bash(systemctl is-enabled *)"
              "Bash(systemctl is-failed *)"
              "Bash(systemctl list-jobs*)"
              "Bash(systemctl list-sockets*)"
              "Bash(systemctl list-timers*)"
              "Bash(systemctl list-unit-files*)"
              "Bash(systemctl list-units*)"
              "Bash(systemctl show *)"
              "Bash(systemctl status *)"
              "WebFetch(domain:raw.githubusercontent.com)"
              "WebFetch(domain:github.com)"
              "WebSearch"
              "mcp__linear__get_project"
              "mcp__linear__list_issues"
              "mcp__linear__get_issue"
              "mcp__linear__list_comments"
              "mcp__linear__extract_images"
              "mcp__linear__get_document"
              "mcp__figma__get_design_context"
              "mcp__figma__get_metadata"
              "mcp__figma__get_screenshot"
              # MCP: the gateway on glyph, by upstream server. Globs follow tool
              # renames upstream; obsidian-vault is left out so its writes prompt.
              "mcp__glyph__aws-knowledge__*"
              "mcp__glyph__basic-memory__*"
              "mcp__glyph__cloudflare-docs__*"
              "mcp__glyph__context7__*"
              "mcp__glyph__deepwiki__*"
              # grafana is read-only; see modules/nixos/llm/grafana-mcp.nix
              "mcp__glyph__grafana__*"
              "mcp__glyph__kagi__*"
              "mcp__glyph__mcp-nixos__*"
              # rc-source serves a read-only store path
              "mcp__glyph__rc-source__*"
            ];
            deny = [];
          };
        };
      };
    })

    (mkIf (cfg.ai.enable && cfg.ai.gateway.enable) {
      programs.mcp = {
        enable = true;
        servers.glyph = {
          url = "http://glyph:8090/mcp";
        };
      };
    })

    (mkIf cfg.containers.enable {
      home.packages = with pkgs; [
        lazydocker
      ];
    })

    # Colima provides the Docker VM on macOS; on Linux it has no use here
    (mkIf (cfg.containers.enable && pkgs.stdenv.isDarwin) {
      services.colima = {
        enable = true;
        profiles.default = {
          isActive = true;
          isService = true;
          settings = {
            cpu = 4;
            disk = 60;
            memory = 8;
            arch = "aarch64";
            mountInotify = true;
          };
        };
      };

      programs.ssh.includes = [
        "~/.colima/ssh_config"
      ];
    })

    (mkIf cfg.javascript.enable {
      home.packages = with pkgs; let
        nodejs = nodejs_24;
        yarn = yarn-berry.override {inherit nodejs;};
      in [
        jo
        nodejs
        yarn
      ];
    })
  ];
}

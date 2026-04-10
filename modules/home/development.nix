{
  config,
  lib,
  llm-profile,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.development;
in {
  options = {
    rc.development = {
      ai = {
        enable = lib.mkEnableOption "tools using LLMs";
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
      home.packages = [pkgs.nono];

      # nono sandbox profile for Claude Code
      # Extends the built-in profile with Nix-specific read paths
      xdg.configFile."nono/profiles/claude-code.json".text = builtins.toJSON {
        meta = {
          name = "claude-code";
          version = "1.0.0";
          description = "Claude Code sandboxed profile for Nix-managed systems";
        };
        extends = "claude-code";
        filesystem = {
          read = [
            "/nix/store"
            "/nix/var/nix/profiles"
            "/run/current-system/sw"
            "$HOME/.nix-profile"
          ];
        };
      };

      programs.claude-code.package = pkgs.symlinkJoin {
        name = "claude-code-nono-wrapped";
        paths =
          [
            (pkgs.writeShellScriptBin "claude" ''
              exec ${pkgs.nono}/bin/nono run --profile claude-code \
                -- ${pkgs.claude-code}/bin/claude "$@"
            '')
            pkgs.claude-code
          ]
          ++ lib.optional pkgs.stdenv.isDarwin
          (pkgs.writeShellScriptBin "claude-login" ''
            exec ${pkgs.nono}/bin/nono run --profile claude-code \
              --allow-launch-services \
              -- ${pkgs.claude-code}/bin/claude "$@"
          '');
      };

      programs.zsh.sessionVariables = {
        # Disable claude-pace API fallback; rate limits come from stdin on CC >= 2.1.80
        CLAUDE_PACE_API_FALLBACK = "0";
      };

      programs.mcp = {
        enable = true;
        servers.glyph = {
          url = "http://glyph:8090/mcp";
        };
      };

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        memory.source = "${llm-profile}/README.md";
        settings = {
          model = "sonnet";
          # Disabled in favor of Basic Memory MCP for cross-device access
          autoMemoryEnabled = false;
          allowUnsandboxedCommands = false;
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
              # Graphite: info
              "Bash(gt log*)"
              "Bash(gt l*)"
              "Bash(gt ls*)"
              "Bash(gt status*)"
              "Bash(gt info*)"
              "Bash(gt children*)"
              "Bash(gt parent*)"
              # Graphite: navigation
              "Bash(gt checkout *)"
              "Bash(gt co *)"
              "Bash(gt up*)"
              "Bash(gt u)"
              "Bash(gt u *)"
              "Bash(gt down*)"
              "Bash(gt d)"
              "Bash(gt d *)"
              "Bash(gt top*)"
              "Bash(gt t)"
              "Bash(gt t *)"
              "Bash(gt bottom*)"
              "Bash(gt b)"
              "Bash(gt b *)"
              "Bash(gt trunk*)"
              # Graphite: workflow
              "Bash(gt create *)"
              "Bash(gt c *)"
              "Bash(gt modify *)"
              "Bash(gt m *)"
              "Bash(gt submit*)"
              "Bash(gt s)"
              "Bash(gt s *)"
              "Bash(gt ss*)"
              "Bash(gt restack*)"
              "Bash(gt sync*)"
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
              # MCP: basic-memory
              "mcp__glyph__basic-memory__build_context"
              "mcp__glyph__basic-memory__canvas"
              "mcp__glyph__basic-memory__create_memory_project"
              "mcp__glyph__basic-memory__delete_note"
              "mcp__glyph__basic-memory__delete_project"
              "mcp__glyph__basic-memory__edit_note"
              "mcp__glyph__basic-memory__fetch"
              "mcp__glyph__basic-memory__list_directory"
              "mcp__glyph__basic-memory__list_memory_projects"
              "mcp__glyph__basic-memory__move_note"
              "mcp__glyph__basic-memory__read_content"
              "mcp__glyph__basic-memory__read_note"
              "mcp__glyph__basic-memory__recent_activity"
              "mcp__glyph__basic-memory__search"
              "mcp__glyph__basic-memory__search_by_metadata"
              "mcp__glyph__basic-memory__search_notes"
              "mcp__glyph__basic-memory__view_note"
              "mcp__glyph__basic-memory__write_note"
              # MCP: context7
              "mcp__glyph__context7__resolve-library-id"
              "mcp__glyph__context7__query-docs"
              # MCP: graphite
              "mcp__glyph__graphite__learn_gt"
              "mcp__glyph__graphite__run_gt_cmd"
              # MCP: mcp-nixos
              "mcp__glyph__mcp-nixos__nix"
              "mcp__glyph__mcp-nixos__nix_versions"
              # MCP: deepwiki
              "mcp__glyph__deepwiki__ask_question"
              "mcp__glyph__deepwiki__read_wiki_contents"
              "mcp__glyph__deepwiki__read_wiki_structure"
              # MCP: kagi
              "mcp__glyph__kagi__kagi_search_fetch"
              "mcp__glyph__kagi__kagi_summarizer"
              # MCP: aws-knowledge
              "mcp__glyph__aws-knowledge__aws___get_regional_availability"
              "mcp__glyph__aws-knowledge__aws___list_regions"
              "mcp__glyph__aws-knowledge__aws___read_documentation"
              "mcp__glyph__aws-knowledge__aws___recommend"
              "mcp__glyph__aws-knowledge__aws___search_documentation"
              # MCP: grafana
              "mcp__glyph__grafana__add_activity_to_incident"
              "mcp__glyph__grafana__alerting_manage_routing"
              "mcp__glyph__grafana__alerting_manage_rules"
              "mcp__glyph__grafana__create_annotation"
              "mcp__glyph__grafana__create_folder"
              "mcp__glyph__grafana__create_incident"
              "mcp__glyph__grafana__fetch_pyroscope_profile"
              "mcp__glyph__grafana__find_error_pattern_logs"
              "mcp__glyph__grafana__find_slow_requests"
              "mcp__glyph__grafana__generate_deeplink"
              "mcp__glyph__grafana__get_alert_group"
              "mcp__glyph__grafana__get_annotation_tags"
              "mcp__glyph__grafana__get_annotations"
              "mcp__glyph__grafana__get_assertions"
              "mcp__glyph__grafana__get_current_oncall_users"
              "mcp__glyph__grafana__get_dashboard_by_uid"
              "mcp__glyph__grafana__get_dashboard_panel_queries"
              "mcp__glyph__grafana__get_dashboard_property"
              "mcp__glyph__grafana__get_dashboard_summary"
              "mcp__glyph__grafana__get_datasource"
              "mcp__glyph__grafana__get_incident"
              "mcp__glyph__grafana__get_oncall_shift"
              "mcp__glyph__grafana__get_panel_image"
              "mcp__glyph__grafana__get_sift_analysis"
              "mcp__glyph__grafana__get_sift_investigation"
              "mcp__glyph__grafana__list_alert_groups"
              "mcp__glyph__grafana__list_datasources"
              "mcp__glyph__grafana__list_incidents"
              "mcp__glyph__grafana__list_loki_label_names"
              "mcp__glyph__grafana__list_loki_label_values"
              "mcp__glyph__grafana__list_oncall_schedules"
              "mcp__glyph__grafana__list_oncall_teams"
              "mcp__glyph__grafana__list_oncall_users"
              "mcp__glyph__grafana__list_prometheus_label_names"
              "mcp__glyph__grafana__list_prometheus_label_values"
              "mcp__glyph__grafana__list_prometheus_metric_metadata"
              "mcp__glyph__grafana__list_prometheus_metric_names"
              "mcp__glyph__grafana__list_pyroscope_label_names"
              "mcp__glyph__grafana__list_pyroscope_label_values"
              "mcp__glyph__grafana__list_pyroscope_profile_types"
              "mcp__glyph__grafana__list_sift_investigations"
              "mcp__glyph__grafana__query_loki_logs"
              "mcp__glyph__grafana__query_loki_patterns"
              "mcp__glyph__grafana__query_loki_stats"
              "mcp__glyph__grafana__query_prometheus"
              "mcp__glyph__grafana__query_prometheus_histogram"
              "mcp__glyph__grafana__search_dashboards"
              "mcp__glyph__grafana__search_folders"
              "mcp__glyph__grafana__update_annotation"
              "mcp__glyph__grafana__update_dashboard"
            ];
            deny = [];
          };
        };
      };
    })

    (mkIf cfg.containers.enable {
      home.packages = with pkgs; [
        lazydocker
      ];

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

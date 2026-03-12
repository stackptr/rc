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
      age.secrets.claude-code-api-key = {
        file = ../../home/secrets/claude-code-api-key.age;
      };

      programs.zsh.initExtra = ''
        export ANTHROPIC_API_KEY="$(cat ${config.age.secrets.claude-code-api-key.path})"
      '';

      programs.claude-code = {
        enable = true;
        memory.source = "${llm-profile}/README.md";
        mcpServers = {
          glyph = {
            type = "http";
            url = "http://glyph:8090/mcp";
          };
        };
        settings = {
          model = "opus";
          # Disabled in favor of Basic Memory MCP for cross-device access
          autoMemoryEnabled = false;
          enabledMcpjsonServers = ["linear" "figma"];
          permissions = {
            allow = [
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
              # Graphite
              "Bash(gt log*)"
              "Bash(gt ls*)"
              "Bash(gt status*)"
              # System
              "Bash(journalctl:*)"
              "Bash(mkdir *)"
              "Bash(systemctl list-jobs:*)"
              "Bash(systemctl status:*)"
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
            ];
            deny = [];
          };
        };
      };
    })

    (mkIf cfg.containers.enable {
      home.packages = with pkgs; [
        colima
        docker
        lazydocker
      ];

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

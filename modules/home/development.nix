{
  config,
  lib,
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
      programs.claude-code = {
        enable = true;
        settings = {
          model = "opus";
          enableAllProjectMcpServers = true;
          enabledMcpjsonServers = ["linear"];
          permissions = {
            allow = [
              "Bash(find *)"
              "Bash(echo *)"
              "Bash(grep *)"
              "Bash(rg *)"
              "Bash(head *)"
              "Bash(tail *)"
              "Bash(cat *)"
              "Bash(ls *)"
              "Bash(wc *)"
              "Bash(which *)"
              "Bash(nix *)"
              "Bash(git log *)"
              "Bash(git diff *)"
              "Bash(git status)"
              "Bash(git show *)"
              "Bash(git branch *)"
              "Bash(* --version)"
              "Bash(* --help *)"
              "mcp__linear__get_project"
              "mcp__linear__list_issues"
              "mcp__linear__get_issue"
              "mcp__linear__list_comments"
              "mcp__linear__extract_images"
              "mcp__linear__get_document"
              "mcp__figma__get_design_context"
              "mcp__figma__get_metadata"
              "mcp__figma__get_screenshot"
            ];
            deny = [
              "Bash(git push *)"
              "Bash(git reset *)"
              "Bash(git checkout *)"
              "Bash(rm *)"
              "Bash(sudo *)"
              "Bash(nixos-rebuild *)"
              "Bash(darwin-rebuild *)"
            ];
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

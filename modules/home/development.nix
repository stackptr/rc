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
          permissions = {
            allow = [
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

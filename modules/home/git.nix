{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.git;
in {
  options = {
    rc.git = {
      enable = lib.mkEnableOption "Git-related configuration";

      enableHubWrapper = lib.mkEnableOption "hub wrapper for git";

      enableInteractiveRebase = lib.mkEnableOption "interactive rebase";
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [
        pkgs.onefetch
      ];

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.git = {
        enable = true;
        signing = {
          key = "F88C08579051AB48";
          signByDefault = true;
        };
        settings = {
          user = {
            name = "✿ corey";
            email = "corey@x64.co";
          };
          pull.rebase = true;
          push.autosetupremote = true;
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;
        };
      };

      programs.gpg = {
        enable = true;
      };
    })

    (mkIf cfg.enableHubWrapper {
      home.packages = [pkgs.hub];

      programs.zsh.shellAliases = {
        git = "hub";
      };
    })

    (mkIf cfg.enableInteractiveRebase {
      home.packages = [pkgs.git-interactive-rebase-tool];

      programs.git.settings.sequence.editor = "interactive-rebase-tool";
    })
  ];
}

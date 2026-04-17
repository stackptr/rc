{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  gitCfg = config.rc.git;
  graphiteCfg = config.rc.graphite;
  jjCfg = config.rc.jujutsu;
in {
  options = {
    rc.git = {
      enable = lib.mkEnableOption "Git-related configuration";

      enableHubWrapper = mkOption {
        default = true;
        example = true;
        description = "Whether to enable hub wrapper for git.";
        type = lib.types.bool;
      };

      enableInteractiveRebase = mkOption {
        default = true;
        example = true;
        description = "Whether to enable interactive rebase.";
        type = lib.types.bool;
      };
    };

    rc.graphite = {
      enable = lib.mkEnableOption "Graphite CLI";
    };

    rc.jujutsu = {
      enable = lib.mkEnableOption "Jujutsu version control";
    };
  };

  config = lib.mkMerge [
    (mkIf gitCfg.enable {
      home.packages = [
        pkgs.onefetch
      ];

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.git = {
        enable = true;
        signing.format = lib.mkDefault null;
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

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };
    })

    (mkIf gitCfg.enableHubWrapper {
      home.packages = [pkgs.hub];

      programs.zsh.shellAliases = {
        git = "${lib.getExe' pkgs.hub "hub"}";
      };
    })

    (mkIf gitCfg.enableInteractiveRebase {
      home.packages = [pkgs.git-interactive-rebase-tool];

      programs.git.settings.sequence.editor = "interactive-rebase-tool";
    })

    (mkIf graphiteCfg.enable {
      home.packages = [pkgs.graphite-cli];

      home.activation.graphiteConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
        config_dir="$HOME/.config/graphite"
        config_file="$config_dir/user_config"
        run mkdir -p "$config_dir"
        if [ ! -f "$config_file" ]; then
          run cp ${
          pkgs.writeText "graphite-user-config" (builtins.toJSON {
            branchPrefix = "corey/";
            branchDate = false;
            branchReplacement = "-";
            skipApplyingPrefixToNonGeneratedBranchNames = true;
            updateAutomatically = false;
          })
        } "$config_file"
          run chmod u+w "$config_file"
        fi
      '';
    })

    (mkIf jjCfg.enable {
      programs.jujutsu = {
        enable = true;
      };
      programs.jjui = {
        enable = true;
      };

      programs.delta = {
        enable = true;
        enableJujutsuIntegration = true;
      };
    })
  ];
}

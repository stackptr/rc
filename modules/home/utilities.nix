{
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.utilities;
in {
  options = {
    rc.utilities = {
      base.enable = lib.mkEnableOption "base utilities";

      file.enable = lib.mkEnableOption "file utilities";

      media.enable = lib.mkEnableOption "media utilities";

      nix.enable = lib.mkEnableOption "Nix utilities";

      system.enable = lib.mkEnableOption "system utilities";
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.base.enable {
      home.packages = [pkgs.uutils-coreutils-noprefix];

      programs.bat = {
        enable = true;
        config = {
          theme = "Sublime Snazzy";
        };
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.jq.enable = true;

      programs.lsd = {
        enable = true;
        settings = {
          icons = {
            theme = "fancy";
          };
        };
      };

      programs.zsh.shellAliases = {
        cat = "${lib.getExe config.programs.bat.package} -p";
      };
    })

    (mkIf cfg.file.enable {
      home.packages = [
        pkgs.dua
        pkgs.fd
        pkgs.tree
        pkgs.unzip
      ];

      programs.ripgrep.enable = true;

      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
      };
    })

    (mkIf cfg.media.enable {
      home.packages = [
        pkgs.ffmpeg_6
        pkgs.mediainfo
        pkgs.sox
      ];

      programs.yt-dlp = {
        enable = true;
        package = pkgs-stable.yt-dlp;
      };
    })

    (mkIf cfg.nix.enable {
      home.packages =
        [
          pkgs.comma
          pkgs.manix
          pkgs.nix-du
          pkgs.nix-tree
          pkgs.nix-your-shell
        ]
        ++ [
          # TODO: Expose these to Zed editor specifically
          pkgs.alejandra
          pkgs.nil
        ];

      programs.nh.enable = true;
    })

    (mkIf cfg.system.enable {
      home.packages = [pkgs.neofetch];

      programs.btop.enable = true;

      programs.htop.enable = true;
    })
  ];
}

{
  config,
  lib,
  pkgs,
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
      home.packages = [pkgs.coreutils-full];

      programs.bat = {
        enable = true;
        config = {
          theme = "Sublime Snazzy";
        };
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

      programs.yt-dlp.enable = true;
    })

    (mkIf cfg.nix.enable {
      home.packages = [
        pkgs.comma
        pkgs.manix
        pkgs.nix-du
        pkgs.nix-tree
        pkgs.nix-your-shell
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

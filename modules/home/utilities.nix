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
      file.enable = lib.mkEnableOption "file utilities";

      media.enable = lib.mkEnableOption "media utilities";

      system.enable = lib.mkEnableOption "system utilities";
    };
  };

  config = lib.mkMerge [
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

    (mkIf cfg.system.enable {
      programs.btop.enable = true;

      programs.htop.enable = true;
    })
  ];
}

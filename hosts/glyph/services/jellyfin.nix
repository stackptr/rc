{
  config,
  pkgs,
  lib,
  ...
}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
      enableIntelLowPowerEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        vp9 = true;
        av1 = true;
        mpeg2 = true;
        vc1 = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = false; # Intel Arc only
      };
    };
  };

  users.users.${config.services.jellyfin.user}.extraGroups = [
    "video"
    "render"
  ];

  services.meilisearch = {
    enable = true;
  };
}

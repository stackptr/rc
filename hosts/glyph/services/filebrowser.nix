{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.filebrowser-quantum;
  port = 8080;
  settings = {
    server = {
      inherit port;
      sources = [
        {
          path = "/mnt/media";
          config = {
            defaultEnabled = true;
          };
        }
      ];
    };
    auth = {
      adminUsername = "admin";
    };
  };
in {
  services.filebrowser-quantum = {
    enable = true;
    openFirewall = false;
    inherit settings;
  };
  users.users.${cfg.user}.extraGroups = ["media"];
}

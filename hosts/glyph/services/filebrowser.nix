{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.filebrowser-quantum;
in {
  services.filebrowser-quantum = {
    enable = true;
    openFirewall = false;
    settings = {
      server = {
        port = 8080;
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
  };
  users.users.${cfg.user}.extraGroups = ["media"];
}

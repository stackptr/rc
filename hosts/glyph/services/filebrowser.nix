{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.filebrowser;
  address = "";
  port = 8080;
  dataDir = "/var/lib/filebrowser";
  rootDir = "${dataDir}/files";
  settings = {
    inherit address port;
    database = "${dataDir}/filebrowser.db";
    root = rootDir;
    noauth = true;
  };
in {
  services.filebrowser = {
    enable = true;
    openFirewall = false;
    inherit settings;
  };
  users.users.${cfg.user}.extraGroups = ["media"];
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  address = "";
  port = 8080;
  dataDir = "/var/lib/filebrowser";
  rootDir = "${dataDir}/files";
  cacheDir = "/var/cache/filebrowser";
  configFile = pkgs.writeText "filebrowser-config.json" (lib.generators.toJSON {} {
    inherit address port;
    database = "${dataDir}/filebrowser.db";
    root = rootDir;
    cache-dir = cacheDir;
    noauth = true;
    # TODO
    #cert = cfg.tlsCertificate;
    #key = cfg.tlsCertificateKey;
  });
in {
  # TODO: Replace with module option after NixOS/nixpkgs#289750
  users.users.filebrowser = {
    group = "filebrowser";
    home = dataDir;
    createHome = true;
    description = "File Browser daemon user";
    isSystemUser = true;
    extraGroups = ["media"];
  };
  users.groups.filebrowser = {};

  systemd.packages = [pkgs.filebrowser];

  systemd.services.filebrowser = {
    description = "File Browser service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    environment.HOME = "/var/lib/filebrowser";

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      User = "filebrowser";
      Group = "filebrowser";
      StateDirectory = "filebrowser";

      DynamicUser = lib.mkForce false;

      # Basic hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      DevicePolicy = "closed";
      ProtectSystem = "strict";
      ProtectHome = "tmpfs";
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;

      ExecStartPre = ''
        ${pkgs.coreutils}/bin/mkdir -p ${toString rootDir}
      '';

      ExecStart = "${pkgs.filebrowser}/bin/filebrowser --config ${configFile}";
    };
  };
}

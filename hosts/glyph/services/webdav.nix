{_}: {
  services.httpd = {
    enable = true;
    adminAddr = "admin@localhost";
    extraModules = ["dav" "dav_fs" "dav_lock"];
    virtualHosts."docs.zx.dev" = {
      listen = [
        {
          ip = "*";
          port = 8185;
        }
      ];
      documentRoot = "/mnt/documents";
      extraConfig = ''
        DavLockDB /var/lib/httpd/DavLockDB

        <Directory "/mnt/documents">
          DAV On
          Options Indexes
          AllowOverride None
          Require all granted
        </Directory>
      '';
    };
  };

  users.users.wwwrun.extraGroups = ["users"];

  systemd.services.httpd.serviceConfig.ReadWritePaths = ["/mnt/documents"];

  systemd.tmpfiles.rules = [
    "d /mnt/documents 2775 colleen users -"
    "d /var/lib/httpd 0755 wwwrun wwwrun -"
  ];
}

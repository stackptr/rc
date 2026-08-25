{pkgs, ...}: {
  services.nginx = {
    enable = true;
    additionalModules = [pkgs.nginxModules.dav];
    virtualHosts."docs.zx.dev" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 8185;
        }
      ];
      locations."/" = {
        root = "/mnt/documents";
        extraConfig = ''
          dav_methods PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS;
          dav_access user:rw group:rw;
          create_full_put_path on;
          client_max_body_size 0;
          autoindex on;

          # macOS Finder requires LOCK/UNLOCK to enable write operations.
          # nginx does not implement them; return minimal valid responses.
          if ($request_method = LOCK) {
            add_header Content-Type 'application/xml; charset=utf-8';
            return 200 '<?xml version="1.0" encoding="utf-8"?><D:prop xmlns:D="DAV:"><D:lockdiscovery><D:activelock><D:locktype><D:write/></D:locktype><D:lockscope><D:exclusive/></D:lockscope><D:depth>infinity</D:depth><D:timeout>Second-604800</D:timeout><D:locktoken><D:href>urn:uuid:fe184f2e-6eec-41d0-c765-01adc56113bb</D:href></D:locktoken></D:activelock></D:lockdiscovery></D:prop>';
          }
          if ($request_method = UNLOCK) {
            return 204;
          }
        '';
      };
    };
  };

  users.users.nginx.extraGroups = ["users"];

  systemd.services.nginx.serviceConfig.ReadWritePaths = ["/mnt/documents"];

  systemd.tmpfiles.rules = [
    "d /mnt/documents 2775 colleen users -"
  ];
}

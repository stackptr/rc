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
        '';
      };
    };
  };

  users.users.nginx.extraGroups = ["users"];

  systemd.tmpfiles.rules = [
    "d /mnt/documents 2775 partner users -"
  ];
}

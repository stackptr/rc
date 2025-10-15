{
  config,
  pkgs,
  ...
}: {
  age.secrets.oauth2-proxy-env = {
    file = ./../secrets/oauth2-proxy-env.age;
    mode = "440";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
  };
  age.secrets.pocket-id-encryption-key = {
    file = ./../secrets/pocket-id-encryption-key.age;
    mode = "440";
    owner = config.services.pocket-id.user;
    group = config.services.pocket-id.group;
  };

  rc.web.auth = {
    enable = true;
    issuer = {
      host = "id.zx.dev";
      useACMEHost = "zx.dev";
      encryptionKeyFile = config.age.secrets.pocket-id-encryption-key.path;
    };
    authProxy = {
      host = "oauth.zx.dev"; # TODO: Conflict with Authelia
      domain = ".zx.dev";
      clientID = "shared-sso";
      useACMEHost = "zx.dev";
      keyFile = config.age.secrets.oauth2-proxy-env.path;
    };
  };

  services.nginx = {
    virtualHosts."test.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      requireAuth = true;
      locations."/" = {
        root = "/var/www/test";
        index = "index.html";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/www 0755 root root -"
    "d /var/www/test 0755 root root -"
  ];
  systemd.mounts = let
    testSite = pkgs.writeTextDir "index.html" ''
      <!doctype html>
      <meta charset="utf-8">
      <title>Protected</title>
      <body style="font-family:system-ui;margin:2rem">
        <h1>✅ Authenticated via Pocket ID</h1>
      </body>
    '';
  in [
    {
      what = "${testSite}";
      where = "/var/www/test";
      type = "none";
      options = "bind,ro";
      wantedBy = ["multi-user.target"];
    }
  ];
  systemd.services.nginx = {
    after = ["var-www-test.mount"];
    requires = ["var-www-test.mount"];
    serviceConfig.RequiresMountsFor = ["/var/www/test"];
  };
}

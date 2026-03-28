{
  config,
  pkgs,
  ...
}: {
  age.secrets.oauth2-proxy-env = {
    file = ./../../secrets/oauth2-proxy-env.age;
    mode = "440";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
  };
  age.secrets.pocket-id-encryption-key = {
    file = ./../../secrets/pocket-id-encryption-key.age;
    mode = "440";
    owner = config.services.pocket-id.user;
    inherit (config.services.pocket-id) group;
  };

  rc.web.auth = {
    enable = true;
    issuer = {
      host = "id.zx.dev";
      useACMEHost = "zx.dev";
      encryptionKeyFile = config.age.secrets.pocket-id-encryption-key.path;
      databaseURL = "postgres://pocketid@glyph.rove-duck.ts.net/pocketid";
      localDatabase = false;
    };
    authProxy = {
      host = "oauth.zx.dev";
      domain = ".zx.dev";
      clientID = "shared-sso";
      useACMEHost = "zx.dev";
      keyFile = config.age.secrets.oauth2-proxy-env.path;
    };
  };

  services.oauth2-proxy.extraConfig = {
    skip-jwt-bearer-tokens = true;
    extra-jwt-issuers = "https://id.zx.dev=claude-mcp";
  };
}

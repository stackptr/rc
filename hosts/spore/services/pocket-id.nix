{
  config,
  pkgs,
  ...
}: let
  appHost = "id.zx.dev";
in {
  age.secrets.pocket-id-encryption-key = {
    file = ./../secrets/pocket-id-encryption-key.age;
    mode = "440";
    owner = config.services.pocket-id.user;
    group = config.services.pocket-id.group;
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://${appHost}";
      TRUST_PROXY = true;
      DB_PROVIDER = "postgres";
      DB_CONNECTION_STRING = "host=/run/postgresql user=pocketid dbname=pocketid";
      KEYS_STORAGE = "database";
      ENCRYPTION_KEY_FILE = config.age.secrets.pocket-id-encryption-key.path;
    };
  };

  services.postgresql = {
    ensureDatabases = ["pocketid"];
    ensureUsers = [
      {
        name = "pocketid";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.pocket-id = {
    after = ["postgresql.service" "network-online.target"];
    requires = ["postgresql.service"];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${appHost} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:1411";
        proxyWebsockets = true;
      };
    };
  };
}

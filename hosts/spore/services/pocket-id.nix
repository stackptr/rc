{
  config,
  pkgs,
  ...
}: let
  issuerHost = "id.zx.dev";
  authHost = "auth2.zx.dev"; # TODO: Conflict with Authelia
in {
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

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://${issuerHost}";
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

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    oidcIssuerUrl = "https://${issuerHost}";
    keyFile = config.age.secrets.oauth2-proxy-env.path;
    reverseProxy = true;
    setXauthrequest = true;
    clientID = "shared-sso";
    redirectURL = "https://${authHost}/oauth2/callback";
    cookie.domain = ".zx.dev";
    email.domains = [".zx.dev"];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${issuerHost} = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/" = {
        proxyPass = "http://127.0.0.1:1411";
        proxyWebsockets = true;
      };
    };

    virtualHosts.${authHost} = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/oauth2/" = {
        proxyPass = "http://127.0.0.1:4180";
        proxyWebsockets = true;
      };
      locations."/" = {
        extraConfig = ''
          return 200 '<!doctype html><title>Auth</title><p>oauth2-proxy at ${authHost}</p>';
        '';
      };
    };
  };
}

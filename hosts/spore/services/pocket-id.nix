{
  config,
  pkgs,
  ...
}: let
  issuerHost = "id.zx.dev";
  authHost = "oauth.zx.dev"; # TODO: Conflict with Authelia
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
          default_type text/html;
          add_header Content-Type "text/html; charset=utf-8";
          return 200 '<!doctype html><title>Auth</title><p>oauth2-proxy at ${authHost}</p>';
        '';
      };
    };

    virtualHosts."test.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."=/oauth2/auth" = {
        proxyPass = "http://127.0.0.1:4180";
        extraConfig = ''
          proxy_set_header X-Original-URI $request_uri;
          proxy_set_header X-Real-IP      $remote_addr;
          proxy_set_header X-Scheme       $scheme;
          proxy_set_header X-Forwarded-Host $host;
        '';
      };
      locations."= /".extraConfig = ''
        auth_request /oauth2/auth;
        error_page 401 = https://${authHost}/oauth2/start?rd=$scheme://$http_host$request_uri;

        auth_request_set $auth_user  $upstream_http_x_auth_request_user;
        auth_request_set $auth_email $upstream_http_x_auth_request_email;
        add_header X-Auth-User  $auth_user always;
        add_header X-Auth-Email $auth_email always;

        default_type text/html;
        return 200 '<!doctype html><meta charset="utf-8"><title>Test</title><h1>Test page</h1>';
      '';
    };
  };
}

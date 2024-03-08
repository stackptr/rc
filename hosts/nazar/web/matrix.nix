{
  config,
  pkgs,
  lib,
  ...
}: let
  serverName = "zx.dev";
  httpPort = 8008;
  httpsPort = 8448;
in {
  age.secrets.dendrite-env.file = ./../secrets/dendrite-env.age;
  age.secrets.dendrite-private-key.file = ./../secrets/dendrite-private-key.age;
  security.acme.certs."zx.dev".postRun = ''
    cp -vp fullchain.pem /var/lib/dendrite/server.cert
    cp -vp key.pem /var/lib/dendrite/server.key
    chown dendrite:dendrite /var/lib/dendrite/server.cert
    chown dendrite:dendrite /var/lib/dendrite/server.key
  '';
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."${serverName}" = {
      locations."/.well-known/matrix/server" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin '*';
        '';
        return = let
          jsonResponse = builtins.toJSON {"m.server" = "matrix.${serverName}:${toString httpsPort}";};
        in "200 '${jsonResponse}'";
      };
      locations."/.well-known/matrix/client" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin '*';
        '';
        return = let
          jsonResponse = builtins.toJSON {
            "m.homeserver" = {
              base_url = "https://matrix.${serverName}:${toString httpsPort}";
            };
          };
        in "200 '${jsonResponse}'";
      };
    };
    virtualHosts."matrix.${serverName}" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://127.0.0.1:${toString httpPort}";
      locations."/_matrix/*".proxyPass = "http://127.0.0.1:${toString httpPort}";
    };
  };
  services.dendrite = {
    enable = true;
    inherit httpPort httpsPort;
    tlsCert = "/var/lib/dendrite/server.cert";
    tlsKey = "/var/lib/dendrite/server.key";
    loadCredential = [
      "private_key:${config.age.secrets.dendrite-private-key.path}"
    ];
    environmentFile = config.age.secrets.dendrite-env.path;
    settings = {
      versions = 2;
      global = {
        server_name = serverName;
        private_key = "$CREDENTIALS_DIRECTORY/private_key";
        database = {
          connection_string = "postgres://127.0.0.1/dendrite?sslmode=disable";
          max_open_conns = 100;
          max_idle_conns = 10;
          conn_max_lifetime = -1;
        };
        dns_cache = {
          enabled = true;
          cache_size = 256;
          cache_lifetime = "5m";
        };
      };
      client_api = {
        registration_disabled = true;
        registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
      };
      # Use global.database.connection_string
      app_service_api.database.connection_string = "";
      federation_api.database.connection_string = "";
      key_server.database.connection_string = "";
      media_api.database.connection_string = "";
      mscs.database.connection_string = "";
      relay_api.database.connection_string = "";
      room_server.database.connection_string = "";
      sync_api.database.connection_string = "";
      user_api.account_database.connection_string = "";
      user_api.device_database.connection_string = "";

      federation_api = {
        send_max_retries = 16;
        disable_tls_validation = false;
        disable_http_keepalives = false;
        key_perspectives = [
          {
            server_name = "matrix.org";
            keys = [
              {
                key_id = "ed25519:auto";
                public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
              }
              {
                key_id = "ed25519:a_RXGa";
                public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
              }
            ];
          }
        ];
        prefer_direct_fetch = false;
      };
    };
    openRegistration = false;
  };
  systemd.services.dendrite = {
    # Wait for ACME certs
    wants = ["acme-finished-zx.dev.target"];
    after = ["acme-selfsigned-zx.dev.service"];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "dendrite";
      Group = "dendrite";
    };
  };
  users.users.dendrite = {
    group = "dendrite";
    isSystemUser = true;
  };
  users.groups.dendrite = {};
}

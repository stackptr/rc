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
    settings = let
      connectionString = "postgres://127.0.0.1/dendrite?sslmode=disable";
    in {
      global = {
        server_name = serverName;
        private_key = "$CREDENTIALS_DIRECTORY/private_key";
      };
      client_api = {
        registration_disabled = true;
        registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
      };
      app_service_api.database.connection_string = connectionString;
      federation_api.database.connection_string = connectionString;
      key_server.database.connection_string = connectionString;
      media_api.database.connection_string = connectionString;
      mscs.database.connection_string = connectionString;
      relay_api.database.connection_string = connectionString;
      room_server.database.connection_string = connectionString;
      sync_api.database.connection_string = connectionString;
      user_api.account_database.connection_string = connectionString;
      user_api.device_database.connection_string = connectionString;
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

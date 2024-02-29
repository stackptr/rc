{
  config,
  pkgs,
  lib,
  ...
}: let
  serverName = "zx.dev";
  httpPort = 8008;
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
          jsonResponse = builtins.toJSON {"m.server" = "matrix.${serverName}";};
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
              base_url = "https://matrix.${serverName}";
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
    httpsPort = 8448;
    tlsCert = "/var/lib/dendrite/server.cert";
    tlsKey = "/var/lib/dendrite/server.key";
    loadCredential = [
      "private_key:${config.age.secrets.dendrite-private-key.path}"
    ];
    environmentFile = config.age.secrets.dendrite-env.path;
    settings = let
      databaseBlocks = ["app_service_api.database" "federation_api.database" "key_server.database" "media_api.database" "mscs.database" "relay_api.database" "room_server.database" "sync_api.database" "user_api.account_database" "user_api.device_database"];
      connectionString = "postgres://matrix@127.0.0.1/matrix?sslmode=disable";
      mkConnectionString = name: {
        name = "${name}.connection_string";
        value = connectionString;
      };
      globalConnectionPool = builtins.listToAttrs (map mkConnectionString databaseBlocks);
    in
      {
        global = {
          server_name = serverName;
          private_key = "$CREDENTIALS_DIRECTORY/private_key";
        };
        client_api = {
          registration_disabled = true;
          registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
        };
      }
      // globalConnectionPool;
    openRegistration = false;
    inherit httpPort;
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

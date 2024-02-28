{
  config,
  pkgs,
  ...
}: let
  serverName = "zx.dev";
  httpPort = 8008;
in {
  age.secrets.dendrite-private-key.file = ./../secrets/dendrite-private-key.age;
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
    loadCredential = [
      "private_key:${config.age.secrets.dendrite-private-key.path}"
    ];
    settings = let
      databaseBlocks = ["app_service_api.database" "federation_api.database" "key_server.database" "media_api.database" "mscs.database" "relay_api.database" "room_server.database" "sync_api.database" "user_api.account_database" "user_api.device_database"];
      connectionString = "postgres://127.0.0.1/matrix?sslmode=disable";
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
      }
      // globalConnectionPool;
    openRegistration = false;
    inherit httpPort;
  };
}

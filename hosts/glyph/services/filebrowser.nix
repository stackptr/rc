{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.filebrowser-quantum;
in {
  age.secrets.filebrowser-env = {
    file = ./../secrets/filebrowser-env.age;
    mode = "550";
    owner = cfg.user;
    inherit (cfg) group;
  };

  services.filebrowser-quantum = {
    enable = true;
    openFirewall = false;
    settings = {
      server = {
        port = 8080;
        sources = let
          config = {
            defaultEnabled = true;
          };
        in [
          {
            path = "/mnt/archive";
            inherit config;
          }
          {
            path = "/mnt/backup";
            inherit config;
          }
          {
            path = "/mnt/media";
            inherit config;
          }
          {
            path = "/mnt/torrents";
            inherit config;
          }
          {
            path = "/mnt/unsorted";
            inherit config;
          }
        ];
      };
      auth = {
        methods = {
          password.enabled = false;
          oidc = {
            enabled = true;
            # N.B.: clientId and clientSecret supplied via environment variable
            issuerUrl = "https://id.zx.dev";
            scopes = "email openid profile groups";
            userIdentifier = "preferred_username";
            disableVerifyTLS = false;
            createUser = true;
            adminGroup = "users";
          };
        };
      };
    };
    environmentFile = config.age.secrets.filebrowser-env.path;
  };
  users.users.${cfg.user}.extraGroups = ["media"];
}

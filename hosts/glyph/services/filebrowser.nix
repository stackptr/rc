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
        sources = [
          {
            path = "/mnt/media";
            config = {
              defaultEnabled = true;
            };
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
            adminGroup = "admins";
          };
        };
      };
    };
    environmentFile = config.age.secrets.filebrowser-env.path;
  };
  users.users.${cfg.user}.extraGroups = ["media"];
}

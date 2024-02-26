{
  config,
  pkgs,
  agenix,
  ...
}: {
  containers.web = {
    autoStart = true;
    bindMounts."/etc/ssh/ssh_host_ed25519_key".isReadOnly = true;
    ephemeral = true;
    config = {
      config,
      pkgs,
      ...
    }: {
      imports = [
        agenix.nixosModules.default
        ./authelia-auth.nix
        ./authelia-proxy.nix
      ];
      age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.secrets.cloudflare-dns.file = ./secrets/cloudflare-dns.age;
      age.secrets.jwt-secret = {
        file = ./secrets/jwt-secret.age;
        mode = "440";
        owner = "authelia-main";
        group = "authelia-main";
      };
      age.secrets.session-secret = {
        file = ./secrets/session-secret.age;
        mode = "440";
        owner = "authelia-main";
        group = "authelia-main";
      };
      age.secrets.storage-encryption-key = {
        file = ./secrets/storage-encryption-key.age;
        mode = "440";
        owner = "authelia-main";
        group = "authelia-main";
      };
      age.secrets.notifier-smtp-password = {
        file = ./secrets/notifier-smtp-password.age;
        mode = "440";
        owner = "authelia-main";
        group = "authelia-main";
      };
      security.acme = {
        acceptTerms = true;
        defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
        defaults.email = "corey@zx.dev";
        certs."zx.dev" = {
          domain = "zx.dev";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns.path;
          extraDomainNames = [
            "auth.zx.dev"
            "portainer.zx.dev"
            "dsm.zx.dev"
            "torrents.zx.dev"
          ];
        };
      };
      users.users.nginx.extraGroups = ["acme"];
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        additionalModules = [pkgs.nginxModules.develkit pkgs.nginxModules.set-misc];
        virtualHosts."rey.foo" = {
          # forceSSL = true;
          # useACMEHost = "rey.foo";
          locations."/".return = "302 https://zx.dev";
        };
        virtualHosts."zx.dev" = {
          forceSSL = true;
          useACMEHost = "zx.dev";
          locations."/".proxyPass = "http://zeta.rove-duck.ts.net:3001";
        };
        virtualHosts."auth.zx.dev" = {
          forceSSL = true;
          useACMEHost = "zx.dev";
          useAutheliaProxyConf = true;
          locations."/".proxyPass = "http://127.0.0.1:9091";
          locations."/api/verify".proxyPass = "http://127.0.0.1:9091";
        };
        virtualHosts."portainer.zx.dev" = {
          forceSSL = true;
          useACMEHost = "zx.dev";
          locations."/".proxyPass = "https://zeta.rove-duck.ts.net:9443";
        };
        virtualHosts."dsm.zx.dev" = {
          forceSSL = true;
          useACMEHost = "zx.dev";
          locations."/".proxyPass = "https://melchior.rove-duck.ts.net:5001";
        };
        virtualHosts."torrents.zx.dev" = {
          forceSSL = true;
          useACMEHost = "zx.dev";
          enableAutheliaAuth = true;
          locations."/".proxyPass = "http://melchior.rove-duck.ts.net:9091";
          locations."~ (/transmission)?/rpc".proxyPass = "http://melchior.rove-duck.ts.net:9091";
        };
      };
      services.authelia.instances.main = {
        enable = true;
        secrets.jwtSecretFile = config.age.secrets.jwt-secret.path;
        secrets.sessionSecretFile = config.age.secrets.session-secret.path;
        secrets.storageEncryptionKeyFile = config.age.secrets.storage-encryption-key.path;
        environmentVariables = {
          # N.B.: `secrets.notifierSmtpPasswordFile` is not yet defined
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.notifier-smtp-password.path;
        };
        settings = {
          theme = "auto";
          default_redirection_url = "https://zx.dev";
          default_2fa_method = "webauthn";
          log.level = "debug";
          server.disable_healthcheck = true;
          totp = {
            disable = false;
            issuer = "auth.zx.dev";
            algorithm = "sha1";
            digits = 6;
            period = 30;
            skew = 1;
            secret_size = 32;
          };
          webauthn = {
            disable = false;
            timeout = "60s";
            display_name = "Authelia";
            attestation_conveyance_preference = "indirect";
            user_verification = "preferred";
          };
          authentication_backend = {
            password_reset = {
              disable = false;
              custom_url = "";
            };
            refresh_interval = "5m";
            file = {
              path = pkgs.writeText "users.yaml" ''
                users:
                  corey:
                    disabled: false
                    displayname: "Corey"
                    password: "$argon2id$v=19$m=65536,t=3,p=4$+LRpQS4IVBqbuervtB+30Q$hPR1XADxM9+xQ2o0wLuM/aepOJip4cCn4gNWeEsxWYQ"
                    email: corey@x64.co
                    groups:
                      - admins
              '';
              watch = false;
              password = {
                algorithm = "argon2";
                argon2 = {
                  variant = "argon2id";
                  iterations = 3;
                  memory = 65536;
                  parallelism = 4;
                  key_length = 32;
                  salt_length = 16;
                };
              };
            };
          };
          password_policy = {
            standard = {
              enabled = false;
              min_length = 8;
              max_length = 0;
              require_uppercase = true;
              require_lowercase = true;
              require_number = true;
              require_special = true;
            };
            zxcvbn = {
              enabled = false;
              min_score = 3;
            };
          };
          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = "*.zx.dev";
                policy = "two_factor";
              }
            ];
          };
          session = {
            name = "authelia_session";
            domain = "zx.dev";
            same_site = "lax";
            expiration = "1h";
            inactivity = "5m";
            remember_me_duration = "1M";
          };
          regulation = {
            max_retries = 3;
            find_time = "2m";
            ban_time = "5m";
          };
          storage.local.path = "/var/lib/authelia-main/db.sqlite3";
          notifier = {
            disable_startup_check = false;
            smtp = {
              host = "smtp.sendgrid.net";
              port = 587;
              timeout = "5s";
              username = "apikey";
              sender = "Authelia <authelia@zx.dev>";
              identifier = "auth.zx.dev";
              subject = "[Authelia] {title}";
              startup_check_address = "test@zx.dev";
            };
          };
        };
      };
      services.mastodon = {
        enable = true;
        localDomain = "pub.zx.dev";
        streamingProcesses = 1;
        # TODO:
        # secretKeyBaseFile = config.age.secrets.mastodon-secret-key-base.path;
        # secretKeyBaseFile = config.age.secrets.mastodon-secret-key-base.path;
        # vapidPublicKeyFile = config.age.secrets.mastodon-vapid-public-key.path;
        # vapidPrivateKeyFile = config.age.secrets.mastodon-vapid-private-key.path;
        configureNginx = true;
        database = {
          createLocally = false;
          host = "127.0.0.1";
          port = 5432;
          user = "mastodon";
          passwordFile = "/dev/null"; # Not needed
          name = "mastodon";
        };
        redis = {
          createLocally = false;
          port = 31637;
          enableUnixSocket = false;
        };
        smtp = {
          createLocally = false;
          host = "smtp.sendgrid.net";
          port = 587;
          authenticate = true;
          user = "apikey";
          passwordFile = config.age.secrets.notifier-smtp-password.path;
          fromAddress = "mastodon@zx.dev";
        };
        extraConfig.SINGLE_USER_MODE = "true";
      };
      system.stateVersion = "24.05";
    };
  };
}

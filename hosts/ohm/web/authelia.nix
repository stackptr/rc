{
  config,
  pkgs,
  ...
}: {
  age.secrets.jwt-secret = {
    file = ./../secrets/jwt-secret.age;
    mode = "440";
    owner = "authelia-main";
    group = "authelia-main";
  };
  age.secrets.session-secret = {
    file = ./../secrets/session-secret.age;
    mode = "440";
    owner = "authelia-main";
    group = "authelia-main";
  };
  age.secrets.storage-encryption-key = {
    file = ./../secrets/storage-encryption-key.age;
    mode = "440";
    owner = "authelia-main";
    group = "authelia-main";
  };
  age.secrets.notifier-smtp-password = {
    file = ./../secrets/notifier-smtp-password.age;
    mode = "440";
    owner = "authelia-main";
    group = "authelia-main";
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
                password: "$argon2id$v=19$m=65536,t=3,p=4$/jiiAPT7PHKhKxb3ncrLBQ$8cWd3PZKhBJvEz8KfGnC3FEYS1LTMSKRbzR1WsDbCIg"
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
}

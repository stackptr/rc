{
  config,
  pkgs,
  ...
}: {
  age.secrets.cloudflare-dns.file = ./secrets/cloudflare-dns.age;
  age.secrets.ldap-admin-password.file = ./secrets/ldap-admin-password.age;
  age.secrets.jwt-secret.file = ./secrets/jwt-secret.age;
  age.secrets.session-secret.file = ./secrets/session-secret.age;
  age.secrets.storage-encryption-key.file = ./secrets/storage-encryption-key.age;
  age.secrets.notifier-smtp-password.file = ./secrets/notifier-smtp-password.age;
  containers.web = {
    autoStart = true;
    bindMounts = {
      cloudflareDns = {
        mountPoint = "/run/secrets/cloudflare-dns";
        hostPath = config.age.secrets.cloudflare-dns.path;
      };
      ldapAdminPassword = {
        mountPoint = "/run/secrets/ldap-admin-password";
        hostPath = config.age.secrets.ldap-admin-password.path;
      };
      jwtSecret = {
        mountPoint = "/run/secrets/jwt-secret";
        hostPath = config.age.secrets.jwt-secret.path;
      };
      session-secret = {
        mountPoint = "/run/secrets/session-secret";
        hostPath = config.age.secrets.session-secret.path;
      };
      storage-encryption-key = {
        mountPoint = "/run/secrets/storage-encryption-key";
        hostPath = config.age.secrets.storage-encryption-key.path;
      };
      notifier-smtp-password = {
        mountPoint = "/run/secrets/notifier-smtp-password";
        hostPath = config.age.secrets.notifier-smtp-password.path;
      };
    };
    ephemeral = true;
    config = {
      config,
      pkgs,
      ...
    }: {
      security.acme = {
        acceptTerms = true;
        defaults.email = "admin@xor.ooo";
        certs."xor.ooo" = {
          domain = "*.xor.ooo";
          dnsProvider = "cloudflare";
          environmentFile = "/run/secrets/cloudflare-dns";
          extraDomainNames = ["xor.ooo"];
        };
        certs."rey.foo" = {
          domain = "rey.foo";
          dnsProvider = "cloudflare";
          environmentFile = "/run/secrets/cloudflare-dns";
        };
      };
      users.users.nginx.extraGroups = [ "acme" ];
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."rey.foo" = {
          forceSSL = true;
          useACMEHost = "rey.foo";
          locations."/".return = "302 https://xor.ooo";
        };
        virtualHosts."xor.ooo" = {
          forceSSL = true;
          useACMEHost = "xor.ooo";
          locations."/".proxyPass = "http://zeta.rove-duck.ts.net:3001";
        };
        virtualHosts."portainer.xor.ooo" = {
          forceSSL = true;
          useACMEHost = "xor.ooo";
          locations."/".proxyPass = "https://zeta.rove-duck.ts.net:9443";
        };
      };
      services.openldap = {
        enable = true;
        urlList = [ "ldap:///" ];
        settings.children = {
          "olcDatabase={1}mdb".attrs = {
            objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
            
            olcDatabase = "{1}mdb";
            olcDbDirectory = "/var/lib/openldap/data";
            
            olcSuffix = "dc=xor,dc=ooo";
            olcRootDN = "cn=admin,dc=xor,dc=ooo";
            olcRootPW.path = "/run/secrets/ldap-admin-password";
            olcAccess = [
              /* custom access rules for userPassword attributes */
              ''{0}to attrs=userPassword
                  by self write
                  by anonymous auth
                  by * none''
            
              /* allow read on anything else */
              ''{1}to *
                  by * read''
            ];
          };
        };
      }; 
      services.authelia.instances.main = {
        enable = true;
        secrets.jwtSecretFile = "/run/secrets/jwt-secret";
        secrets.sessionSecretFile = "/run/secrets/session-secret";
        secrets.storageEncryptionKeyFile = "/run/secrets/storage-encryption-key";
        environmentVariables = {
          # N.B.: `secrets.notifierSmtpPasswordFile` is not yet defined
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = "/run/secrets/notifier-smtp-password";
        };
        settings = {
          theme = "auto";
          default_redirection_url = "https://xor.ooo";
          default_2fa_method = "webauthn";
          log.level = "debug";
          server.disable_healthcheck = true;
          totp = {
            disable = false;
            issuer = "auth.xor.ooo";
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
            ldap = {
              implementation = "custom";
              url = "ldap://openldap:1389";
              timeout = "5s";
              start_tls = false;
              base_dn = "dc=xor,dc=ooo";
              users_filter = "(&({username_attribute}={input})(objectClass=person))";
              username_attribute = "uid";
              mail_attribute = "mail";
              display_name_attribute = "displayName";
              groups_filter = "(&(member={dn})(objectClass=groupOfNames))";
              group_name_attribute = "cn";
              permit_referrals = false;
              permit_unauthenticated_bind = false;
              user = "cn=admin,dc=xor,dc=ooo";
              password = "f738e96f7b81405470a66dba196f1cfa9e915a430c2ec2d2";
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
          session = {
            name = "authelia_session";
            domain = "xor.ooo";
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
          notifier = {
            disable_startup_check = false;
            smtp = {
              host = "smtp.sendgrid.net";
              port = 587;
              timeout = "5s";
              username = "apikey";
              sender = "Authelia <authelia@xor.ooo>";
              identifier = "auth.xor.ooo";
              subject = "[Authelia] {title}";
              startup_check_address = "test@xor.ooo";
            };
          };
        };
      };
      system.stateVersion = "24.05";
    };
  };
}

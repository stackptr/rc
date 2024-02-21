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
      imports = [agenix.nixosModules.default];
      age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      age.secrets.cloudflare-dns.file = ./secrets/cloudflare-dns.age;
      age.secrets.ldap-admin-password = {
        file = ./secrets/ldap-admin-password.age;
        mode = "440";
        owner = "openldap";
        group = "openldap";
      };
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
        defaults.email = "admin@xor.ooo";
        certs."xor.ooo" = {
          domain = "*.xor.ooo";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns.path;
          extraDomainNames = ["xor.ooo"];
        };
        certs."rey.foo" = {
          domain = "rey.foo";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns.path;
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
            olcRootPW.path = config.age.secrets.ldap-admin-password.path;
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
        secrets.jwtSecretFile = config.age.secrets.jwt-secret.path;
        secrets.sessionSecretFile = config.age.secrets.session-secret.path;
        secrets.storageEncryptionKeyFile = config.age.secrets.storage-encryption-key.path;
        environmentVariables = {
          # N.B.: `secrets.notifierSmtpPasswordFile` is not yet defined
          AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.notifier-smtp-password.path;
          AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.ldap-admin-password.path;
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
              url = "ldap://localhost:389";
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
                domain = "*.xor.ooo";
                policy = "two_factor";
              }
            ];
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
          storage.local.path = "/var/lib/authelia-main/db.sqlite3";
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

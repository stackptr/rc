{
  config,
  pkgs,
  lib,
  ...
}: let
  enable = false;
in {
  age.secrets = lib.mkIf enable {
    mastodon-s3-env = {
      file = ./../secrets/mastodon-s3-env.age;
      mode = "440";
      owner = "mastodon";
      group = "mastodon";
    };
    mastodon-smtp-password = {
      file = ./../secrets/notifier-smtp-password.age;
      mode = "440";
      owner = "mastodon";
      group = "mastodon";
    };
    mastodon-secret-key-base = {
      file = ./../secrets/mastodon-secret-key-base.age;
      mode = "440";
      owner = "mastodon";
      group = "mastodon";
    };
    mastodon-vapid-public-key = {
      file = ./../secrets/mastodon-vapid-public-key.age;
      mode = "440";
      owner = "mastodon";
      group = "mastodon";
    };
    mastodon-vapid-private-key = {
      file = ./../secrets/mastodon-vapid-private-key.age;
      mode = "440";
      owner = "mastodon";
      group = "mastodon";
    };
  };
  services.mastodon = {
    inherit enable;
    localDomain = "pub.zx.dev";
    streamingProcesses = 1;
    secretKeyBaseFile = config.age.secrets.mastodon-secret-key-base.path;
    vapidPublicKeyFile = config.age.secrets.mastodon-vapid-public-key.path;
    vapidPrivateKeyFile = config.age.secrets.mastodon-vapid-private-key.path;
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
      passwordFile = config.age.secrets.mastodon-smtp-password.path;
      fromAddress = "mastodon@zx.dev";
    };
    extraConfig = {
      SINGLE_USER_MODE = "true";
      LOCAL_DOMAIN = "zx.dev";
      WEB_DOMAIN = "pub.zx.dev";
      S3_ENABLED = "true";
      S3_ALIAS_HOST = "media.zx.dev";
      S3_BUCKET = "mastodon";
      S3_ENDPOINT = "https://9c12166db465350c0f02410b390d0cbc.r2.cloudflarestorage.com/";
      S3_PROTOCOL = "https";
      S3_PERMISSION = "private";
    };
    extraEnvFiles = [
      config.age.secrets.mastodon-s3-env.path
    ];
  };

  services.postgresql = lib.mkIf enable {
    ensureUsers = [
      {
        name = "mastodon";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["mastodon"];
  };
  services.postgresqlBackup = {
    #inherit enable;
    databases = ["mastodon"];
  };
  services.redis.servers.mastodon = {
    inherit enable;
    port = 31637;
  };
}

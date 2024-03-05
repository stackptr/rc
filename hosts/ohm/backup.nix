{
  config,
  pkgs,
  ...
}: {
  age.secrets.restic-env.file = ./secrets/restic-env.age;
  age.secrets.restic-password.file = ./secrets/restic-password.age;
  services.restic.backups = {
    daily = {
      initialize = true;

      environmentFile = config.age.secrets.restic-env.path;
      passwordFile = config.age.secrets.restic-password.path;

      repository = "s3:https://9c12166db465350c0f02410b390d0cbc.r2.cloudflarestorage.com/restic";
      paths = [
        config.services.postgresqlBackup.location
      ];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
    };
  };
}

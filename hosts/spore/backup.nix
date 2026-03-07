{config, ...}: {
  services.restic-backup = {
    enable = true;
    paths = [
      config.services.postgresqlBackup.location
    ];
  };
}

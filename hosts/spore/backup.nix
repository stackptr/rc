{config, ...}: {
  rc.backup = {
    enable = true;
    paths = [
      config.services.postgresqlBackup.location
    ];
  };
}

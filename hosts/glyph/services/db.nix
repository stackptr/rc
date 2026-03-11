{pkgs, ...}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local  all   all                  trust
      host   all   all   127.0.0.1/32   trust
      host   all   all   100.64.0.0/10  trust
    '';
    settings = {
      port = 5432;
      max_connections = 150;
    };
    ensureDatabases = ["atticd" "open-webui" "pocketid"];
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
      {
        name = "open-webui";
        ensureDBOwnership = true;
      }
      {
        name = "pocketid";
        ensureDBOwnership = true;
      }
    ];
  };

  services.postgresqlBackup = {
    enable = true;
    databases = ["atticd" "open-webui" "pocketid"];
  };
}

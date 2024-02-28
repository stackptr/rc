{
  config,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    port = 5432;
    ensureUsers = [
      {
        name = "mastodon";
        ensureDBOwnership = true;
      }
      {
        name = "matrix";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["mastodon" "matrix"];
    authentication = pkgs.lib.mkOverride 10 ''
      # Any user can connect to any database via Unix socket or local loopback
      local  all   all                  trust
      host   all   all   127.0.0.1/32   trust
    '';
  };
  services.postgresqlBackup = {
    enable = true;
    databases = ["mastodon"];
  };
  services.redis.servers.mastodon = {
    enable = true;
    port = 31637;
  };
}

{
  config,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    ensureUsers = [
      {
        name = "mastodon";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["mastodon"];
    authentication = pkgs.lib.mkOverride 10 ''
      # Any user can connect to any database via Unix socket, local loopback,
      # or Tailscale
      local  all   all                  trust
      host   all   all   127.0.0.1/32   trust
      host   all   all   100.64.0.0/10  trust
    '';
    settings = {
      port = 5432;
      max_connections = 150;
    };
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

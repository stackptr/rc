{pkgs, ...}: let
  # WireGuard authenticates a tailnet packet's source address, so a tailnet
  # /32 names one machine. Update it if spore re-registers.
  spore = {
    v4 = "100.89.150.33";
    v6 = "fd7a:115c:a1e0::a033:9621";
  };
in {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    # Local connections are trusted: services here use the socket or
    # loopback, and the tailnet lockout procedure in CLAUDE.md tunnels
    # spore's Pocket ID to 127.0.0.1. Over the tailnet each client gets only
    # its own database and role, never a superuser, which could run commands
    # on glyph with COPY ... FROM PROGRAM. Mastodon on spore (disabled)
    # needs its own line if it comes back.
    authentication = pkgs.lib.mkOverride 10 ''
      local  all       all                         trust
      host   all       all       127.0.0.1/32      trust
      host   pocketid  pocketid  ${spore.v4}/32    trust
      host   pocketid  pocketid  ${spore.v6}/128   trust
    '';
    settings = {
      port = 5432;
      max_connections = 150;
    };
    ensureDatabases = ["atticd" "audiomuse" "freshrss" "grafana" "open-webui" "pocketid"];
    ensureUsers = [
      {
        name = "mu";
        ensureClauses.superuser = true;
      }
      {
        # pgAdmin (pgadmin.nix) connects as this role, not as mu
        name = "pgadmin";
        ensureClauses.superuser = true;
      }
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
      {
        name = "audiomuse";
        ensureDBOwnership = true;
      }
      {
        name = "freshrss";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
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
    databases = ["atticd" "audiomuse" "freshrss" "grafana" "open-webui" "pocketid"];
  };
}

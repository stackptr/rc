{config, ...}: let
  port = 8084;
in {
  services.freshrss = {
    enable = true;
    baseUrl = "https://rss.zx.dev";
    virtualHost = "rss.zx.dev";
    defaultUser = "corey";
    # spore puts rss.zx.dev behind Pocket ID and passes the username as
    # Remote-User; FreshRSS trusts it only from TRUSTED_PROXY below.
    authType = "http_auth";
    # Reeder uses the Google Reader API with a per-user API password set in
    # FreshRSS's profile settings, not the login password.
    api.enable = true;
    database = {
      type = "pgsql";
      host = "/run/postgresql"; # socket; port stays null
      user = "freshrss";
      name = "freshrss";
    };
  };

  # Reachable only over the tailnet; spore proxies rss.zx.dev to it. Both
  # address families, since MagicDNS resolves glyph to IPv4 and IPv6.
  services.nginx.virtualHosts."rss.zx.dev".listen = [
    {
      addr = "0.0.0.0";
      inherit port;
    }
    {
      addr = "[::]";
      inherit port;
    }
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [port];

  # Replaces FreshRSS's trusted_sources (loopback by default). The whole
  # tailnet, not just spore: 8084 is reachable only over it, and glyph's
  # Postgres already trusts the same range.
  services.phpfpm.pools.${config.services.freshrss.pool}.phpEnv.TRUSTED_PROXY = "100.64.0.0/10 fd7a:115c:a1e0::/48";

  # The module doesn't order its setup unit after a local database. The
  # target, not postgresql.service: ensureDatabases and ensureUsers run in
  # postgresql-setup.service.
  systemd.services.freshrss-config = {
    after = ["postgresql.target"];
    requires = ["postgresql.target"];
  };
}

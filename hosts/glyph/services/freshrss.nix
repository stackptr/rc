{config, ...}: let
  port = 8084;
in {
  age.secrets.freshrss-password = {
    file = ./../secrets/freshrss-password.age;
    mode = "400";
    owner = config.services.freshrss.user;
  };

  services.freshrss = {
    enable = true;
    baseUrl = "https://rss.zx.dev";
    virtualHost = "rss.zx.dev";
    defaultUser = "corey";
    authType = "form";
    passwordFile = config.age.secrets.freshrss-password.path;
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

  # The module doesn't order its setup unit after a local database. The
  # target, not postgresql.service: ensureDatabases and ensureUsers run in
  # postgresql-setup.service.
  systemd.services.freshrss-config = {
    after = ["postgresql.target"];
    requires = ["postgresql.target"];
  };
}

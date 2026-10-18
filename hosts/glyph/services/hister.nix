# Hister: full-text search over pages I've visited. The browser extension
# posts each rendered page here; search.zx.dev on spore proxies the web UI and
# API over the tailnet. Logins go through Pocket ID (OIDC only); the extension,
# CLI and MCP use a personal access token from the profile page.
{config, ...}: {
  # HISTER__SERVER__OAUTH__OIDC__CLIENT_ID and __CLIENT_SECRET for the
  # Pocket ID client, whose callback URL is
  # https://search.zx.dev/api/oauth/callback?provider=oidc
  age.secrets.hister-env = {
    file = ./../secrets/hister-env.age;
    mode = "400";
    owner = config.services.hister.user;
    inherit (config.services.hister) group;
  };

  services.hister = {
    enable = true;
    environmentFile = config.age.secrets.hister-env.path;
    settings = {
      app = {
        user_handling = true;
        search_url = "https://kagi.com/search?q={query}";
      };
      server = {
        # All interfaces so spore reaches it over the tailnet; the firewall
        # only trusts tailscale0, so the LAN can't.
        address = "0.0.0.0:4433";
        base_url = "https://search.zx.dev";
        # Over the socket, which glyph's Postgres trusts (db.nix)
        database = "host=/run/postgresql user=hister dbname=hister sslmode=disable";
        oauth_only = true;
        oauth.oidc.configuration_url = "https://id.zx.dev/.well-known/openid-configuration";
      };
    };
  };

  # The target, not postgresql.service: ensureDatabases and ensureUsers run in
  # postgresql-setup.service.
  systemd.services.hister = {
    after = ["postgresql.target"];
    requires = ["postgresql.target"];
  };
}

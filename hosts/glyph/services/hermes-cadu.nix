# Trial: Hermes's desktop backend (`hermes serve`) for Cadu, the iOS client
# (cadu.bot). Separate from ./hermes.nix so dropping the trial is one import.
#
# This widens the lockdown in hermes.nix. The backend is an admin surface,
# not just chat: a client can manage profiles, skills, plugins, MCP servers
# and cron jobs, and /api/pty runs the Hermes TUI. The model's tool limits
# don't apply to the client. So it binds to the tailnet name only (glyph's
# firewall trusts tailscale0; nothing listens publicly), and any non-loopback
# bind makes Hermes require a login: the bundled username/password provider,
# whose hash and session-signing secret come from agenix. Hermes rejects its
# plain session token in that mode, so backend.sessionTokenFile isn't used.
{config, ...}: let
  host = "glyph.note-iwato.ts.net";
  port = 9119;
in {
  age.secrets.hermes-dashboard-env.file = ./../secrets/hermes-dashboard-env.age;

  services.hermes-agent = {
    backend = {
      mode = "serve"; # the API Cadu and Hermes Desktop use, without the web UI
      inherit host port;
      # The server rejects requests whose Host isn't the bind name, so
      # clients must use http://glyph.note-iwato.ts.net:9119. Wait for
      # MagicDNS at boot; the bind fails until tailscaled is up.
      waitFor = "hostname";
    };
    # HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH (scrypt$…) and
    # HERMES_DASHBOARD_BASIC_AUTH_SECRET (stable session signing).
    environmentFiles = [config.age.secrets.hermes-dashboard-env.path];
    settings.dashboard.basic_auth.username = "corey";
  };

  # .env is rewritten at activation, but each process reads it only at start.
  systemd.services = {
    hermes-agent.restartTriggers = [config.age.secrets.hermes-dashboard-env.file];
    hermes-backend.restartTriggers = [
      config.age.secrets.hermes-omlx-env.file
      config.age.secrets.hermes-slack-env.file
      config.age.secrets.hermes-dashboard-env.file
    ];
  };
}

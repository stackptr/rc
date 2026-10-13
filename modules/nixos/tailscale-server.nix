# Servers on the tailnet carry tag:server, so their keys never expire and
# they don't belong to a user. If one is logged out anyway, it rejoins with
# an auth key instead of a browser login: that login goes through id.zx.dev,
# which itself needs glyph and spore on the tailnet (see "Tailnet lockout"
# in CLAUDE.md).
{
  config,
  lib,
  ...
}: let
  cfg = config.rc.tailscale.server;
in {
  options.rc.tailscale.server = {
    enable = lib.mkEnableOption "Tailscale as a tag:server node that rejoins with an auth key";
    ssh = lib.mkEnableOption "Tailscale SSH";
  };

  config = lib.mkIf cfg.enable {
    # The secret of the "server-join" OAuth client (Trust credentials in the
    # admin console): Auth keys write scope, limited to tag:server.
    age.secrets.tailscale-server-key.file = ../../secrets/tailscale-server-key.age;

    services.tailscale = {
      enable = true;
      # Used only while tailscaled is logged out, by tailscaled-autoconnect
      # at boot; after a logout at runtime, restart that unit.
      authKeyFile = config.age.secrets.tailscale-server-key.path;
      authKeyParameters = {
        ephemeral = false;
        preauthorized = true;
      };
      # Keys from an OAuth client must name the tags they're for.
      extraUpFlags = ["--advertise-tags=tag:server"] ++ lib.optional cfg.ssh "--ssh";
    };
  };
}

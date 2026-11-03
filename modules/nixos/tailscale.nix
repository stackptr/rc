# Deploys reach every host over the tailnet, so a switch that restarts
# tailscaled cuts the deploy off mid-activation. On glyph (2026-10-22) that
# cancelled deploy-rs's activation, and the rollback it started died when
# the runner left the tailnet, leaving most units stopped until the next
# switch. A new tailscaled takes effect at the next reboot or
# `systemctl restart tailscaled`.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.tailscale.enable {
    systemd.services.tailscaled.restartIfChanged = false;
  };
}

# Starts Claude's 5-hour usage window before the workday, so it resets at
# noon instead of mid-afternoon: one window covers the morning, a fresh one
# the afternoon peak. Weekdays at 07:00, before work usually starts (a later
# first message would open the window itself).
#
# power.nix keeps lobtop awake on AC, so no scheduled wake; launchd runs a run
# missed during sleep once the Mac wakes. Haiku keeps the ping cheap; the
# window is shared across models. No --strict-mcp-config: Claude Code refuses
# it while Lob's managed-mcp.json is present.
{
  config,
  lib,
  username,
  ...
}: let
  log = "${config.users.users.${username}.home}/Library/Logs/claude-warm.log";
in {
  # `command`, not ProgramArguments: nix-darwin wraps it in wait4path, so a
  # boot before the Nix volume mounts doesn't leave the agent broken.
  launchd.user.agents.claude-warm = {
    command = lib.escapeShellArgs [
      "/etc/profiles/per-user/${username}/bin/claude"
      "-p"
      "ok"
      "--model"
      "haiku"
      "--no-session-persistence"
    ];
    serviceConfig = {
      StartCalendarInterval = map (day: {
        Weekday = day;
        Hour = 7;
        Minute = 0;
      }) [1 2 3 4 5];
      # Cloudflare Gateway intercepts TLS (managed-device.nix). Set here rather
      # than relying on the node-extra-ca-certs agent having run first.
      EnvironmentVariables.NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      StandardOutPath = log;
      StandardErrorPath = log;
    };
  };
}

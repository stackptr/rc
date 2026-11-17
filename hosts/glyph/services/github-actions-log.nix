# GitHub Actions history in Loki, for Grafana and the agents: every hour,
# ./github-actions-log.sh logs each run and job completed in the repos the
# teleometer app is installed on, with the tail of each failed job's log,
# as JSON lines in this unit's journal:
#
#   {unit="github-actions-log.service"} | json | kind="run"
#
# teleometer is read-only (Actions and Checks) and has no webhook; its key is
# readable only by this unit's user.
{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "github-actions-log";
  poll = pkgs.writeShellApplication {
    name = "github-actions-log";
    runtimeInputs = with pkgs; [coreutils curl gnugrep gnused jq openssl];
    text = builtins.readFile ./github-actions-log.sh;
    # Its jq programs are single-quoted: their $names are jq's own
    excludeShellChecks = ["SC2016"];
  };
in {
  age.secrets.github-actions-log-key = {
    file = ../../../lib/admin/github-apps/teleometer.age;
    owner = user;
  };

  users.users.${user} = {
    isSystemUser = true;
    group = user;
  };
  users.groups.${user} = {};

  systemd.services.github-actions-log = {
    description = "Log GitHub Actions runs and jobs";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    environment = {
      APP_CLIENT_ID = "Iv23liroeutHTNeLtwl5";
      APP_OWNER = "stackptr";
      APP_KEY = config.age.secrets.github-actions-log-key.path;
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe poll;
      User = user;
      Group = user;
      # Each repo's watermark
      StateDirectory = "github-actions-log";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    };
  };
  systemd.timers.github-actions-log = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}

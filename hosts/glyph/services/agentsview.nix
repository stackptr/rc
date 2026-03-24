{
  config,
  pkgs,
  ...
}: let
  port = 8095;
  configFile = pkgs.writeText "agentsview-config.toml" ''
    [pg]
    url = "postgres://agentsview@localhost:5432/agentsview?sslmode=disable"
    machine_name = "glyph"
  '';

  # pg push starts a watcher after syncing; wrap it to exit after sync
  pgPushScript = pkgs.writeShellScript "agentsview-pg-push" ''
    ${pkgs.agentsview}/bin/agentsview pg push &
    PID=$!
    # Wait for sync to complete, then kill the watcher
    sleep 15
    kill $PID 2>/dev/null || true
  '';
in {
  # Serve the aggregated team dashboard from PostgreSQL
  systemd.services.agentsview = {
    description = "Agentsview team dashboard";
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    preStart = ''
      mkdir -p /var/lib/agentsview/.agentsview
      cp ${configFile} /var/lib/agentsview/.agentsview/config.toml
    '';
    serviceConfig = {
      ExecStart = "${pkgs.agentsview}/bin/agentsview pg serve -host 127.0.0.1 -port ${toString port}";
      DynamicUser = true;
      User = "agentsview";
      Group = "agentsview";
      StateDirectory = "agentsview";
      RuntimeDirectory = "agentsview";
      Environment = "HOME=/var/lib/agentsview";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Push local glyph sessions to PostgreSQL every 10 minutes
  systemd.timers.agentsview-pg-push = {
    description = "Push agentsview sessions to PostgreSQL";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };

  systemd.services.agentsview-pg-push = {
    description = "Push agentsview sessions to PostgreSQL";
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pgPushScript;
      User = "mu";
      Group = "users";
      Environment = "HOME=/home/mu";
      TimeoutStartSec = 60;
    };
  };
}

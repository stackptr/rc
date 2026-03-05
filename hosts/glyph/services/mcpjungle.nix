{pkgs, ...}: {
  users.users.mcpjungle = {
    isSystemUser = true;
    group = "mcpjungle";
  };
  users.groups.mcpjungle = {};

  systemd.services.mcpjungle = {
    description = "MCPJungle MCP Gateway";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.mcpjungle}/bin/mcpjungle start --port 8090";
      User = "mcpjungle";
      Group = "mcpjungle";
      WorkingDirectory = "/var/lib/mcpjungle";
      StateDirectory = "mcpjungle";
      Restart = "on-failure";
      RestartSec = 5;

      # Hardening
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/mcpjungle"];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };
}

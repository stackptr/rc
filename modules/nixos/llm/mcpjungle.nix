{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.mcpjungle;
in {
  options.services.mcpjungle = {
    enable = lib.mkEnableOption "MCPJungle MCP Gateway";

    package = lib.mkPackageOption pkgs "mcpjungle" {};

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port for the HTTP server to listen on.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for MCPJungle";
  };

  config = lib.mkIf cfg.enable {
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
        ExecStart = "${lib.getExe cfg.package} start --port ${toString cfg.port}";
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

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

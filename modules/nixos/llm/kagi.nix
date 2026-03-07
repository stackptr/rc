{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.kagi-mcp;

  startScript = pkgs.writeShellScript "kagi-mcp-start" ''
    exec ${lib.getExe pkgs.uv} run --with kagimcp python -c "
    from kagimcp.server import mcp
    mcp.settings.host = '${cfg.host}'
    mcp.settings.port = ${toString cfg.port}
    mcp.run(transport='streamable-http')
    "
  '';
in {
  options.services.kagi-mcp = {
    enable = lib.mkEnableOption "Kagi MCP server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8093;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to environment file containing KAGI_API_KEY.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for Kagi MCP";
  };

  config = lib.mkIf cfg.enable {
    users.users.kagi-mcp = {
      isSystemUser = true;
      group = "kagi-mcp";
      home = "/var/lib/kagi-mcp";
    };
    users.groups.kagi-mcp = {};

    systemd.services.kagi-mcp = {
      description = "Kagi MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = "/var/lib/kagi-mcp";
        UV_CACHE_DIR = "/var/lib/kagi-mcp/.cache/uv";
      };

      serviceConfig = {
        ExecStart = "${startScript}";
        EnvironmentFile = cfg.environmentFile;
        User = "kagi-mcp";
        Group = "kagi-mcp";
        WorkingDirectory = "/var/lib/kagi-mcp";
        StateDirectory = "kagi-mcp";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        BindPaths = ["/var/lib/kagi-mcp"];
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/kagi-mcp"];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    programs.nix-ld.enable = true;

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

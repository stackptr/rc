{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.mcp-nixos;
in {
  options.services.mcp-nixos = {
    enable = lib.mkEnableOption "MCP NixOS server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8092;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for MCP NixOS";
  };

  config = lib.mkIf cfg.enable {
    users.users.mcp-nixos = {
      isSystemUser = true;
      group = "mcp-nixos";
      home = "/var/lib/mcp-nixos";
    };
    users.groups.mcp-nixos = {};

    systemd.services.mcp-nixos = {
      description = "MCP NixOS Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = "/var/lib/mcp-nixos";
        MCP_NIXOS_TRANSPORT = "http";
        MCP_NIXOS_HOST = cfg.host;
        MCP_NIXOS_PORT = toString cfg.port;
      };

      serviceConfig = {
        ExecStart = lib.getExe pkgs.mcp-nixos;
        User = "mcp-nixos";
        Group = "mcp-nixos";
        WorkingDirectory = "/var/lib/mcp-nixos";
        StateDirectory = "mcp-nixos";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        BindPaths = ["/var/lib/mcp-nixos"];
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/mcp-nixos"];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

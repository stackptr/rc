{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.rc-source-mcp;

  startScript = pkgs.writeShellScript "rc-source-mcp-start" ''
    exec ${lib.getExe pkgs.mcp-proxy} \
      --host ${cfg.host} \
      --port ${toString cfg.port} \
      --transport streamablehttp \
      -- ${lib.getExe pkgs.mcp-server-filesystem} ${lib.escapeShellArg cfg.sourcePath}
  '';
in {
  options.services.rc-source-mcp = {
    enable = lib.mkEnableOption "read-only rc source filesystem MCP server (stdio→HTTP bridge)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8098;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    sourcePath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the rc source tree to serve (typically a read-only store path).";
    };

    openFirewall = lib.mkEnableOption "opening firewall port for rc-source-mcp";
  };

  config = lib.mkIf cfg.enable {
    users.users.rc-source-mcp = {
      isSystemUser = true;
      group = "rc-source-mcp";
    };
    users.groups.rc-source-mcp = {};

    systemd.services.rc-source-mcp = {
      description = "rc Source Filesystem MCP Server (read-only)";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${startScript}";
        User = "rc-source-mcp";
        Group = "rc-source-mcp";
        WorkingDirectory = "/";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadOnlyPaths = [cfg.sourcePath];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

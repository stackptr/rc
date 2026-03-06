{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.basic-memory;
  dataDir = "/var/lib/basic-memory";
in {
  options.services.basic-memory = {
    enable = lib.mkEnableOption "Basic Memory MCP server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8091;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for Basic Memory";
  };

  config = lib.mkIf cfg.enable {
    users.users.basic-memory = {
      isSystemUser = true;
      group = "basic-memory";
      home = dataDir;
    };
    users.groups.basic-memory = {};

    systemd.services.basic-memory = {
      description = "Basic Memory MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = dataDir;
        BASIC_MEMORY_CONFIG_DIR = dataDir;
        UV_CACHE_DIR = "${dataDir}/.cache/uv";
      };

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.uv} tool run basic-memory mcp --transport streamable-http --port ${toString cfg.port} --host ${cfg.host}";
        User = "basic-memory";
        Group = "basic-memory";
        WorkingDirectory = dataDir;
        StateDirectory = "basic-memory";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        BindPaths = ["${dataDir}"];
        ProtectSystem = "strict";
        ReadWritePaths = [dataDir];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.grafana-mcp;

  startScript = pkgs.writeShellScript "grafana-mcp-start" ''
    exec ${lib.getExe pkgs.mcp-proxy} \
      --host ${cfg.host} \
      --port ${toString cfg.port} \
      --transport streamablehttp \
      -- ${lib.getExe pkgs.mcp-grafana}
  '';
in {
  options.services.grafana-mcp = {
    enable = lib.mkEnableOption "Grafana MCP server (stdio→HTTP bridge)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8095;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    grafanaUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL of the Grafana instance to connect to.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the Grafana service account token.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for Grafana MCP";
  };

  config = lib.mkIf cfg.enable {
    users.users.grafana-mcp = {
      isSystemUser = true;
      group = "grafana-mcp";
      home = "/var/lib/grafana-mcp";
    };
    users.groups.grafana-mcp = {};

    systemd.services.grafana-mcp = {
      description = "Grafana MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        HOME = "/var/lib/grafana-mcp";
        GRAFANA_URL = cfg.grafanaUrl;
      };

      serviceConfig = {
        ExecStart = "${startScript}";
        User = "grafana-mcp";
        Group = "grafana-mcp";
        WorkingDirectory = "/var/lib/grafana-mcp";
        StateDirectory = "grafana-mcp";
        EnvironmentFile = cfg.tokenFile;
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        BindPaths = ["/var/lib/grafana-mcp"];
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/grafana-mcp"];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

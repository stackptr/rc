{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.graphite-mcp;

  preStartScript = pkgs.writeShellScript "graphite-mcp-prestart" ''
    mkdir -p "$HOME/.config/graphite"
    token=$(cat "${cfg.authTokenFile}")
    printf '{"authToken":"%s"}' "$token" > "$HOME/.config/graphite/user_config"
    chmod 600 "$HOME/.config/graphite/user_config"
  '';

  startScript = pkgs.writeShellScript "graphite-mcp-start" ''
    exec ${lib.getExe pkgs.mcp-proxy} \
      --host ${cfg.host} \
      --port ${toString cfg.port} \
      --transport streamablehttp \
      -- ${lib.getExe pkgs.graphite-cli} mcp
  '';
in {
  options.services.graphite-mcp = {
    enable = lib.mkEnableOption "Graphite MCP server (stdio→HTTP bridge)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8094;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    authTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the Graphite auth token.";
    };

    openFirewall = lib.mkEnableOption "opening firewall ports for Graphite MCP";
  };

  config = lib.mkIf cfg.enable {
    users.users.graphite-mcp = {
      isSystemUser = true;
      group = "graphite-mcp";
      home = "/var/lib/graphite-mcp";
    };
    users.groups.graphite-mcp = {};

    systemd.services.graphite-mcp = {
      description = "Graphite MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      path = [pkgs.git];

      environment = {
        HOME = "/var/lib/graphite-mcp";
      };

      serviceConfig = {
        ExecStartPre = "${preStartScript}";
        ExecStart = "${startScript}";
        User = "graphite-mcp";
        Group = "graphite-mcp";
        WorkingDirectory = "/var/lib/graphite-mcp";
        StateDirectory = "graphite-mcp";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = "tmpfs";
        BindPaths = ["/var/lib/graphite-mcp"];
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/graphite-mcp"];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

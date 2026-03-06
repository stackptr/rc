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

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Streamable HTTP URL of the MCP server.";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Description of the MCP server.";
          };
        };
      });
      default = {};
      description = "MCP servers to register with the gateway.";
    };
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

    systemd.services.mcpjungle-register = lib.mkIf (cfg.servers != {}) {
      description = "Register MCP servers with MCPJungle";
      after = ["mcpjungle.service"];
      requires = ["mcpjungle.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = let
        registry = "http://127.0.0.1:${toString cfg.port}";
        bin = lib.getExe cfg.package;
        registrations = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: server: ''
            if ! ${bin} list servers --registry ${registry} 2>/dev/null | grep -q '${name}'; then
              ${bin} register --name '${name}' --description '${server.description}' --url '${server.url}' --registry ${registry}
            fi
          '')
          cfg.servers);
      in ''
        ${registrations}
      '';
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

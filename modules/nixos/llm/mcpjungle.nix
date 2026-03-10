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
          headers = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = ''
              Custom HTTP headers to send with requests to this server.
              Values may reference environment variables (e.g. "$MY_API_KEY")
              which will be substituted from the environmentFile.
            '';
          };
          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to environment file for variable substitution in headers.";
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

    systemd.timers.mcpjungle-register = lib.mkIf (cfg.servers != {}) {
      description = "Trigger MCP server registration";
      wantedBy = ["timers.target"];
      # Re-trigger when server configuration changes
      restartTriggers = [(builtins.hashString "sha256" (builtins.toJSON cfg.servers))];
      timerConfig = {
        OnActiveSec = "5s";
      };
    };

    systemd.services.mcpjungle-register = lib.mkIf (cfg.servers != {}) {
      description = "Register MCP servers with MCPJungle";
      after = ["mcpjungle.service"];
      requires = ["mcpjungle.service"];
      # Prevent NixOS activation from blocking on this oneshot
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
      };
      path = [pkgs.curl pkgs.envsubst];
      script = let
        registry = "http://127.0.0.1:${toString cfg.port}";
        bin = lib.getExe cfg.package;

        mkRegistration = name: server: let
          hasHeaders = server.headers != {};
          configJson = builtins.toJSON {
            inherit name;
            inherit (server) url description headers;
            transport = "streamable-http";
          };
          registerCmd =
            if hasHeaders
            then ''
              ${lib.optionalString (server.environmentFile != null) ''
                set -a
                source "${server.environmentFile}"
                set +a
              ''}
              tmpfile=$(mktemp --suffix=.json)
              echo '${configJson}' | envsubst > "$tmpfile"
              ${bin} register --conf "$tmpfile" --registry ${registry} || echo "ERROR: failed to register ${name}"
              rm -f "$tmpfile"
            ''
            else ''
              ${bin} register --name '${name}' --description '${server.description}' --url '${server.url}' --registry ${registry} || echo "ERROR: failed to register ${name}"
            '';
        in ''
          if ${bin} list servers --registry ${registry} 2>/dev/null | grep -q '${name}'; then
            echo "${name} already registered, skipping."
          else

          # Wait for server to be reachable before registering
          ready=false
          for i in $(seq 1 30); do
            http_code=$(curl -s -o /dev/null -w '%{http_code}' "${server.url}" 2>/dev/null || true)
            if [ "$http_code" != "000" ]; then
              ready=true
              break
            fi
            echo "Waiting for ${name} at ${server.url} (attempt $i/30)..."
            sleep 2
          done

          if [ "$ready" = true ]; then
            ${registerCmd}
          else
            echo "WARNING: ${name} at ${server.url} not reachable after 60s, skipping registration."
          fi

          fi
        '';

        mkBackgroundRegistration = name: server: ''
          (
            ${mkRegistration name server}
          ) &
        '';

        registrations = lib.concatStringsSep "\n" (lib.mapAttrsToList mkBackgroundRegistration cfg.servers);
      in ''
        ${registrations}
        wait
      '';
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

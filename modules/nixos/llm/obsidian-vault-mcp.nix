{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.obsidian-vault-mcp;

  startScript = pkgs.writeShellScript "obsidian-vault-mcp-start" ''
    exec ${lib.getExe pkgs.mcp-proxy} \
      --host ${cfg.host} \
      --port ${toString cfg.port} \
      --transport streamablehttp \
      -- ${lib.getExe pkgs.mcp-server-filesystem} ${lib.escapeShellArg cfg.vaultPath}
  '';
in {
  options.services.obsidian-vault-mcp = {
    enable = lib.mkEnableOption "Obsidian vault filesystem MCP server (stdio→HTTP bridge)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8097;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    vaultPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the Obsidian vault directory.";
    };

    openFirewall = lib.mkEnableOption "opening firewall port for obsidian-vault-mcp";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.obsidian-vault-mcp = {
      description = "Obsidian Vault Filesystem MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${startScript}";
        # Runs as the shared obsidian user so it has full read/write access
        # to vault files created by obsidian-sync.
        User = "obsidian";
        Group = "obsidian";
        WorkingDirectory = "/var/lib/obsidian";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.vaultPath "/var/lib/obsidian"];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.goodlinks-mcp;
in {
  options.services.goodlinks-mcp = {
    enable = lib.mkEnableOption "GoodLinks MCP server (a client of GoodLinks' API on Stroma)";

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

    goodlinksUrl = lib.mkOption {
      type = lib.types.str;
      example = "http://stroma.note-iwato.ts.net:9429/api/v1";
      description = "Base URL of the GoodLinks API.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the GoodLinks API token.";
    };

    openFirewall = lib.mkEnableOption "opening firewall port for goodlinks-mcp";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.goodlinks-mcp = {
      description = "GoodLinks MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        GOODLINKS_URL = cfg.goodlinksUrl;
        GOODLINKS_MCP_HOST = cfg.host;
        GOODLINKS_MCP_PORT = toString cfg.port;
      };

      serviceConfig = {
        ExecStart = lib.getExe pkgs.goodlinks-mcp;
        # The token is read as root and handed over as
        # $CREDENTIALS_DIRECTORY/goodlinks-token, so the secret itself can
        # stay root-only (mode 400).
        DynamicUser = true;
        LoadCredential = "goodlinks-token:${cfg.tokenFile}";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];
  };
}

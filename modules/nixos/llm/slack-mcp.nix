{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.slack-mcp;
in {
  options.services.slack-mcp = {
    enable = lib.mkEnableOption "Slack MCP server (korotovsky/slack-mcp-server)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8100;
      description = "Port for the streamable HTTP transport.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the HTTP server to.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Environment file with SLACK_MCP_XOXB_TOKEN. Use a bot token: the bot
        sees only the channels it's invited to, and its scopes, not this
        module, decide whether it can post.
      '';
    };

    enabledTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["channels_list" "conversations_history" "conversations_replies"];
      description = ''
        Tools to serve. An empty list serves every tool, including ones that
        post, react and join channels, so keep this explicit.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enabledTools != [];
        message = "services.slack-mcp.enabledTools must not be empty: an empty list enables every tool.";
      }
    ];

    systemd.services.slack-mcp = {
      description = "Slack MCP Server";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        SLACK_MCP_HOST = cfg.host;
        SLACK_MCP_PORT = toString cfg.port;
        # Users and channels cache, under $XDG_CACHE_HOME/slack-mcp-server
        XDG_CACHE_HOME = "/var/cache/slack-mcp";
        SLACK_MCP_LOG_FORMAT = "json";
        NO_COLOR = "1";
      };

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.slack-mcp-server)
          "--transport"
          "http"
          "--enabled-tools"
          (lib.concatStringsSep "," cfg.enabledTools)
        ];
        DynamicUser = true;
        CacheDirectory = "slack-mcp";
        # Read by systemd as root, so the secret can stay root-owned.
        EnvironmentFile = cfg.environmentFile;
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
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      };
    };
  };
}

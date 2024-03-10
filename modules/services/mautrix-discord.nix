{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.mautrix-discord;
  dataDir = "/var/lib/mautrix-discord";
  registrationFile = "${dataDir}/discord-registration.yaml";
  settingsFile = "${dataDir}/config.json";
  settingsFileUnsubstituted = settingsFormat.generate "mautrix-discord-config-unsubstituted.json" cfg.settings;
  settingsFormat = pkgs.formats.json {};
  appservicePort = 29334;

  mkDefaults = lib.mapAttrsRecursive (n: v: lib.mkDefault v);
  defaultConfig = {
    homeserver.address = "http://localhost:8448";
    appservice = {
      hostname = "[::]";
      port = appservicePort;
      database.type = "sqlite3";
      database.uri = "${dataDir}/mautrix-discord.db";
      id = "discord";
      bot.username = "discordbot";
      bot.displayname = "Discord bridge bot";
      as_token = "";
      hs_token = "";
    };
    bridge = {
      username_template = "discord_{{.}}";
      displayname_template = "{{or .GlobalName .Username}}{{if .Bot}} (bot){{end}}";
      channel_name_template = "{{if or (eq .Type 3) (eq .Type 4)}}{{.Name}}{{else}}#{{.Name}}{{end}}";
      guild_name_template = "{{.Name}}";
      double_puppet_server_map = {};
      login_shared_secret_map = {};
      command_prefix = "!discord";
      permissions."*" = "relay";
    };
    logging = {
      min_level = "info";
      writers = lib.singleton {
        type = "stdout";
        format = "pretty-colored";
        time_format = " ";
      };
    };
  };
in {
  options.services.mautrix-discord = {
    enable = lib.mkEnableOption (lib.mdDoc "mautrix-discord, a puppeting/relaybot bridge between Matrix and Discord.");

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = defaultConfig;
      description = lib.mdDoc ''
        {file}`config.yaml` configuration as a Nix attribute set.
        Configuration options should match those described in
        [example-config.yaml](https://github.com/mautrix/discord/blob/main/example-config.yaml).
        Secret tokens should be specified using {option}`environmentFile`
        instead of this world-readable attribute set.
      '';
      example = {
        appservice = {
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix_discord?host=/run/postgresql";
          };
          id = "discord";
          ephemeral_events = false;
        };
        bridge = {
          private_chat_portal_meta = true;
          encryption = {
            allow = true;
            default = true;
            require = true;
          };
          provisioning = {
            shared_secret = "disable";
          };
          permissions = {
            "example.com" = "user";
          };
        };
      };
    };
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = lib.mdDoc ''
        File containing environment variables to be passed to the mautrix-discord service,
        in which secret tokens can be specified securely by optionally defining a value for
        `MAUTRIX_DISCORD_BRIDGE_LOGIN_SHARED_SECRET`.
      '';
    };

    serviceDependencies = lib.mkOption {
      type = with lib.types; listOf str;
      default = lib.optional config.services.dendrite.enable "dendrite.service";
      defaultText = lib.literalExpression ''
        optional config.services.dendrite.enable "dendrite.service"
      '';
      description = lib.mdDoc ''
        List of Systemd services to require and wait for when starting the application service.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.mautrix-discord = {
      isSystemUser = true;
      group = "mautrix-discord";
      home = dataDir;
      description = "Mautrix-Discord bridge user";
    };

    users.groups.mautrix-discord = {};

    services.mautrix-discord.settings = lib.mkMerge (map mkDefaults [
      defaultConfig
      # Note: this is defined here to avoid the docs depending on `config`
      {homeserver.domain = config.services.dendrite.settings.global.server_name;}
    ]);

    systemd.services.mautrix-discord = {
      description = "Mautrix-Discord Service - A Discord bridge for Matrix";

      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"] ++ cfg.serviceDependencies;
      after = ["network-online.target"] ++ cfg.serviceDependencies;

      preStart = ''
        # substitute the settings file by environment variables
        # in this case read from EnvironmentFile
        test -f '${settingsFile}' && rm -f '${settingsFile}'
        old_umask=$(umask)
        umask 0177
        ${pkgs.envsubst}/bin/envsubst \
          -o '${settingsFile}' \
          -i '${settingsFileUnsubstituted}'
        umask $old_umask

        # generate the appservice's registration file if absent
        if [ ! -f '${registrationFile}' ]; then
          ${pkgs.mautrix-discord}/bin/mautrix-discord \
            --generate-registration \
            --config='${settingsFile}' \
            --registration='${registrationFile}'
        fi
        chmod 640 ${registrationFile}

        # Grant Dendrite access to the registration
        if ${pkgs.getent}/bin/getent group dendrite > /dev/null; then
          chgrp -v dendrite ${registrationFile}
          chmod -v g+r ${registrationFile}
        fi

        umask 0177
        ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
          | .[0].appservice.hs_token = .[1].hs_token
          | .[0]' '${settingsFile}' '${registrationFile}' \
          > '${settingsFile}.tmp'
        mv '${settingsFile}.tmp' '${settingsFile}'
        umask $old_umask
      '';

      serviceConfig = {
        User = "mautrix-discord";
        Group = "mautrix-discord";
        EnvironmentFile = cfg.environmentFile;
        StateDirectory = baseNameOf dataDir;
        WorkingDirectory = dataDir;
        ExecStart = ''
          ${pkgs.mautrix-discord}/bin/mautrix-discord \
          --config='${settingsFile}' \
          --registration='${registrationFile}'
        '';
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        Restart = "on-failure";
        RestartSec = "30s";
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = ["@system-service"];
        Type = "simple";
        UMask = 0027;
      };
      restartTriggers = [settingsFileUnsubstituted];
    };
  };
}

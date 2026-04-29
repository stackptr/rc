{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.rc.obsidian-sync;
  stateDir = "/var/lib/obsidian";
in {
  options.rc.obsidian-sync = {
    enable = lib.mkEnableOption "Obsidian headless vault sync";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "${stateDir}/vault";
      description = "Local path to the vault directory.";
    };

    authTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing OBSIDIAN_AUTH_TOKEN=<token>.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.obsidian = {
      isSystemUser = true;
      group = "obsidian";
      home = stateDir;
    };
    users.groups.obsidian = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.vaultPath} 0755 obsidian obsidian -"
      "d ${stateDir}/.config/obsidian-headless 0700 obsidian obsidian -"
    ];

    systemd.services.obsidian-sync = {
      description = "Obsidian headless vault sync";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        User = "obsidian";
        Group = "obsidian";
        WorkingDirectory = stateDir;
        StateDirectory = "obsidian";

        EnvironmentFile = cfg.authTokenFile;

        # Skip (not fail) if vault hasn't been configured via `ob sync-setup` yet
        ExecCondition = "${pkgs.obsidian-headless}/bin/ob sync-status --path ${cfg.vaultPath}";

        ExecStart = "${pkgs.obsidian-headless}/bin/ob sync --continuous --path ${cfg.vaultPath}";

        Restart = "on-failure";
        RestartSec = "30s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.vaultPath "${stateDir}/.config/obsidian-headless"];
      };
    };
  };
}

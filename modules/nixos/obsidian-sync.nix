{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.rc.obsidian-sync;
  homeDir = config.users.users.${username}.home;
in {
  options.rc.obsidian-sync = {
    enable = lib.mkEnableOption "Obsidian headless vault sync";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/vault";
      description = "Local path to the vault directory.";
    };

    authTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing OBSIDIAN_AUTH_TOKEN=<token>.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.vaultPath} 0755 ${username} users -"
      "d ${homeDir}/.config/obsidian-headless 0700 ${username} users -"
    ];

    systemd.services.obsidian-sync = {
      description = "Obsidian headless vault sync";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        User = username;
        Group = "users";
        WorkingDirectory = homeDir;

        EnvironmentFile = cfg.authTokenFile;

        # Skip (not fail) if vault hasn't been configured via `ob sync-setup` yet
        ExecCondition = "${pkgs.obsidian-headless}/bin/ob sync-status --path ${cfg.vaultPath}";

        ExecStart = "${pkgs.obsidian-headless}/bin/ob sync --continuous --path ${cfg.vaultPath}";

        Restart = "on-failure";
        RestartSec = "30s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.vaultPath "${homeDir}/.config/obsidian-headless"];
      };
    };
  };
}

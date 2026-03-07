{
  config,
  lib,
  ...
}: let
  cfg = config.services.restic-backup;
in {
  options.services.restic-backup = {
    enable = lib.mkEnableOption "restic backup to Cloudflare R2";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Paths to back up.";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      description = "Prune options for restic forget.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.restic-env.file = ../../secrets/restic-env.age;
    age.secrets.restic-password.file = ../../secrets/restic-password.age;

    services.restic.backups.daily = {
      initialize = true;

      environmentFile = config.age.secrets.restic-env.path;
      passwordFile = config.age.secrets.restic-password.path;

      repository = "s3:https://9c12166db465350c0f02410b390d0cbc.r2.cloudflarestorage.com/restic";
      inherit (cfg) paths pruneOpts;
    };
  };
}

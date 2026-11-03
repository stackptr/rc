{
  config,
  lib,
  hostname,
  ...
}: let
  cfg = config.rc.backup;
in {
  options.rc.backup = {
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
    # Each backed-up host has its own repo password and R2 token (an API token
    # with Object Read & Write on its bucket only), so no host can read or
    # delete another's backups. R2 tokens can't be limited to a prefix, so a
    # second host needs its own bucket, not a path in this one.
    age.secrets.restic-env.file = ../../hosts/${hostname}/secrets/restic-env.age;
    age.secrets.restic-password.file = ../../hosts/${hostname}/secrets/restic-password.age;

    services.restic.backups.daily = {
      initialize = true;

      environmentFile = config.age.secrets.restic-env.path;
      passwordFile = config.age.secrets.restic-password.path;

      repository = "s3:https://9c12166db465350c0f02410b390d0cbc.r2.cloudflarestorage.com/restic";
      inherit (cfg) paths pruneOpts;
    };
  };
}

{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.daisydisk;
in {
  options.programs.daisydisk = {
    enable = mkEnableOption "DaisyDisk";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [pkgs.daisydisk];
    system.disableUpdates = ["com.daisydiskapp.DaisyDiskStandAlone"];
  };
}

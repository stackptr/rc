{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.daisydisk;
in {
  options.programs.daisydisk = {
    enable = mkEnableOption "DaisyDisk";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.daisydisk];
    system.disableUpdates = ["com.daisydiskapp.DaisyDiskStandAlone"];
  };
}

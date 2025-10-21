{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.little-snitch;
in {
  options.programs.little-snitch = {
    enable = mkEnableOption "Little Snitch";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "little-snitch";
        greedy = true;
      }
    ];
    system.disableUpdates = [
      {
        domain = "at.obdev.littlesnitch.softwareupdate";
        keys = ["SoftwareUpdateCheckAutomatically"];
      }
    ];
  };
}

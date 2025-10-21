{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.postico;
in {
  options.programs.postico = {
    enable = mkEnableOption "Postico";

    startOnActivation = mkEnableOption "starting Postico on activation";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "postico";
        greedy = true;
      }
    ];
    system.disableUpdates = ["at.eggerapps.Postico"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Postico" = "/Applications/Postico\ 2.app/";
    };
  };
}

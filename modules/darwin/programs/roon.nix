{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.roon;
in {
  options.programs.roon = {
    enable = mkEnableOption "Roon client";

    startOnActivation = mkEnableOption "starting Roon on activation";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "roon";
        greedy = true;
      }
    ];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Roon" = "/Applications/Roon.app/";
    };
  };
}

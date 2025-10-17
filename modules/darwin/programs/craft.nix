{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.craft;
in {
  options.programs.craft = {
    enable = mkEnableOption "Craft";

    startOnActivation = mkEnableOption "starting Craft on activation";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "craft";
        greedy = true;
      }
    ];
    system.disableUpdates = ["com.lukilabs.lukiapp"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Craft" = "/Applications/Craft.app/";
    };
  };
}

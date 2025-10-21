{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.soundsource;
in {
  options.programs.soundsource = {
    enable = mkEnableOption "SoundSource";

    startOnActivation = mkEnableOption "starting SoundSource on activation";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.soundsource];
    system.disableUpdates = ["com.rogueamoeba.soundsource"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "SoundSource" = "${pkgs.soundsource}/Applications/SoundSource.app/";
    };
  };
}

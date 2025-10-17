{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.scroll-reverser;
in {
  options.programs.scroll-reverser = {
    enable = mkEnableOption "Scroll Reverser";

    startOnActivation = mkEnableOption "starting Scroll Reverser on activation";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.scroll-reverser];
    system.defaults.CustomUserPreferences = {
      "com.pilotmoon.scroll-reverser" = {
        InvertScrollingOn = true;
        ReverseTrackpad = false;
        ReverseMouse = true;
        ReverseY = true;
        StartAtLogin = true;
      };
    };
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Scroll Reverser" = "${pkgs.scroll-reverser}/Applications/Scroll\ Reverser.app/";
    };
  };
}

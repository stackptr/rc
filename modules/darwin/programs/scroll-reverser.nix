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
    # 2.x sets direction per device, defaulting to natural for trackpads and
    # classic for mice, and no longer reads 1.x's ReverseTrackpad,
    # ReverseMouse or ReverseY.
    system.defaults.CustomUserPreferences = {
      "com.pilotmoon.scroll-reverser" = {
        InvertScrollingOn = true;
        StartAtLogin = true;
      };
    };
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Scroll Reverser" = "${pkgs.scroll-reverser}/Applications/Scroll\ Reverser.app/";
    };
  };
}

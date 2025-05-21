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
    enable = mkEnableOption "Whether to enable Scroll Reverser";
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
  };
}

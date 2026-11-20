{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.meetingbar;
in {
  options.programs.meetingbar = {
    enable = mkEnableOption "MeetingBar";

    startOnActivation = mkEnableOption "starting MeetingBar on activation";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.meetingbar];
    # MeetingBar stores enum settings as JSON, so string values keep their quotes.
    system.defaults.CustomUserPreferences = {
      "leits.MeetingBar" = {
        eventTitleFormat = ''"none"'';
        eventTitleIconFormat = ''"iconCalendar"'';
        eventTimeFormat = ''"show_under_title"'';
        endOfEventNotification = false;
      };
    };
    system.startOnActivation = mkIf cfg.startOnActivation {
      MeetingBar = "${pkgs.meetingbar}/Applications/MeetingBar.app/";
    };
  };
}

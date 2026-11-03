{
  config,
  pkgs,
  ...
}: {
  system.defaults.dock = {
    tilesize = 42;
    largesize = 86;
    persistent-apps = [
      "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
      "/System/Applications/Mail.app"
      "/Applications/Zed.app"
      "/Applications/cmux.app"
      "/Applications/NetNewsWire.app"
      "/Applications/NaviBeat.app" # TestFlight beta, installed by hand
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/System/Applications/Notes.app"
      "/Applications/Things3.app"
      "/System/Applications/Messages.app"
      "/Applications/Slack.app"
    ];
  };
}

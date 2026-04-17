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
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/System/Applications/Notes.app"
      "/Applications/Slack.app"
    ];
  };
}

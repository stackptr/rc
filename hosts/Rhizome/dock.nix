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
      "/Applications/Reeder.app"
      "/Applications/Roon.app"
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/Applications/Obsidian.app"
      "/Applications/Things3.app"
      "/System/Applications/Messages.app"
      "/Applications/Slack.app"
    ];
  };
}

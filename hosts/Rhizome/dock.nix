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
      "/Applications/rootshell.app"
      "/Applications/Reeder.app"
      "/Applications/Roon.app"
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/System/Applications/Notes.app"
      "/Applications/Things3.app"
      "/Applications/Craft.app"
      "/System/Applications/Messages.app"
      "${pkgs.slack}/Applications/Slack.app"
    ];
  };
}

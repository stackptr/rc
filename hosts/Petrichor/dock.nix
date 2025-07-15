{
  config,
  pkgs,
  ...
}: {
  system.defaults.dock = {
    tilesize = 49;
    largesize = 92;
    persistent-apps = [
      "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
      "/Applications/Microsoft Outlook.app"
      "/Applications/Nova.app"
      "/Applications/Prompt.app"
      "/Applications/Reeder.app"
      "/Applications/Roon.app"
      "/System/Applications/Calendar.app"
      "/Applications/Things3.app"
      "/Applications/Craft.app"
      "/System/Applications/Messages.app"
      "${pkgs.slack}/Applications/Slack.app"
      "/Applications/Microsoft Teams.app"
      "${pkgs.github-desktop}/Applications/GitHub Desktop.app"
    ];
  };
}

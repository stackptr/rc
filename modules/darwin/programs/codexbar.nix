{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.codexbar;
in {
  options.programs.codexbar = {
    enable = mkEnableOption "CodexBar";

    startOnActivation = mkEnableOption "starting CodexBar on activation";

    enableNotifications = mkEnableOption "CodexBar's limit reset, quota and pace warning notifications";
  };

  config = mkIf cfg.enable {
    homebrew.casks = ["codexbar"];
    system.defaults.CustomUserPreferences = {
      "com.steipete.codexbar" = {
        usageBarsShowUsed = true;
        tokenCostUsageEnabled = false;
        limitResetNotificationsEnabled = cfg.enableNotifications;
        quotaWarningNotificationsEnabled = cfg.enableNotifications;
        predictivePaceWarningNotificationsEnabled = cfg.enableNotifications;
      };
    };
    system.disableUpdates = ["com.steipete.codexbar"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      CodexBar = "/Applications/CodexBar.app/";
    };
  };
}

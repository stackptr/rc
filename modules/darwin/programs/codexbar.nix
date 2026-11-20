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
  };

  config = mkIf cfg.enable {
    homebrew.casks = ["codexbar"];
    system.defaults.CustomUserPreferences = {
      "com.steipete.codexbar" = {
        usageBarsShowUsed = true;
        tokenCostUsageEnabled = false;
        limitResetNotificationsEnabled = true;
        quotaWarningNotificationsEnabled = true;
        predictivePaceWarningNotificationsEnabled = true;
      };
    };
    system.disableUpdates = ["com.steipete.codexbar"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      CodexBar = "/Applications/CodexBar.app/";
    };
  };
}

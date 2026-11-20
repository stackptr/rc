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

  # The cask rather than nixpkgs' codexbar, which trails releases and wraps the
  # GUI binary as `codexbar`; the cask links the real CLI. Provider settings
  # (the Claude source included) live in ~/.config/codexbar/config.json, which
  # the app rewrites whole, so they stay unmanaged.
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

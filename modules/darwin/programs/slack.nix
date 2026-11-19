{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.slack;
in {
  options.programs.slack = {
    enable = mkEnableOption "Slack";

    installCask = mkOption {
      type = types.bool;
      default = true;
      description = "Install Slack's Homebrew cask. Turn off where something else, like MDM, installs it.";
    };
  };

  config = mkIf (cfg.enable && cfg.installCask) {
    homebrew.casks = ["slack"];
  };
}

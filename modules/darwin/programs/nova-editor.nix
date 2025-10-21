{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.nova-editor;
in {
  options.programs.nova-editor = {
    enable = mkEnableOption "Nova";

    startOnActivation = mkEnableOption "starting Nova on activation";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "nova";
        greedy = true;
      }
    ];
    system.disableUpdates = ["com.panic.Nova"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Nova" = "/Applications/Nova.app/";
    };
  };
}

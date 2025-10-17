{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.tailscale;
in {
  options.programs.tailscale = {
    enable = mkEnableOption "Tailscale";

    startOnActivation = mkEnableOption "starting Tailscale on activation";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      {
        name = "tailscale-app";
        greedy = true;
      }
    ];
    system.disableUpdates = ["io.tailscale.ipn.macsys"];
    system.startOnActivation = mkIf cfg.startOnActivation {
      "Tailscale" = "/Applications/Tailscale.app/";
    };
  };
}

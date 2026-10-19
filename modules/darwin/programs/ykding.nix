{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ykding;
in {
  options.programs.ykding = {
    enable = mkEnableOption "ykding, a sound and banner when a YubiKey waits for a touch";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.ykding];
    # `ykding test` plays both alerts; banners need notifications allowed for
    # Script Editor (osascript).
    launchd.user.agents.ykding = {
      command = "${pkgs.ykding}/bin/ykding run";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}

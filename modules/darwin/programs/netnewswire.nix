{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.netnewswire;
in {
  options.programs.netnewswire = {
    enable = mkEnableOption "NetNewsWire";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.net-news-wire];
    system.disableUpdates = ["com.ranchero.NetNewsWire-Evergreen"];
  };
}

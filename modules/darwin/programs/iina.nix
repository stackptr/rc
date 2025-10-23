{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.iina;
in {
  options.programs.iina = {
    enable = mkEnableOption "iina";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.iina];
    system.disableUpdates = ["com.colliderli.iina"];
  };
}

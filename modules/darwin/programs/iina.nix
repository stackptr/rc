{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.programs.iina;
in {
  options.programs.iina = {
    enable = mkEnableOption "iina";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [pkgs.iina];
    system.disableUpdates = ["com.colliderli.iina"];
  };
}

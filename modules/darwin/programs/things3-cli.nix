{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.things3-cli;
in {
  options.programs.things3-cli = {
    enable = mkEnableOption "things3-cli, a CLI for Things 3";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.things3-cli];
  };
}

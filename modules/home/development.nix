{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.development;
in {
  options = {
    rc.development = {
      containers = {
        enable = lib.mkEnableOption "container-related tooling";
      };

      javascript = {
        enable = lib.mkEnableOption "JavaScript development tooling";
      };
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.containers.enable {
      home.packages = with pkgs; [
        colima
        docker
        lazydocker
      ];
    })

    (mkIf cfg.javascript.enable {
      home.packages = with pkgs; let
        nodejs = nodejs_24;
        yarn = yarn-berry.override {inherit nodejs;};
      in [
        jo
        nodejs
        yarn
      ];
    })
  ];
}

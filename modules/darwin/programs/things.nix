{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.things;
in {
  options.programs.things = {
    enable = mkEnableOption "Things";
  };

  config = mkIf cfg.enable {
    homebrew.masApps."Things" = 904280696;
  };
}

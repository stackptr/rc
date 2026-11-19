{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.t3-code;
in {
  options.programs.t3-code = {
    enable = mkEnableOption "T3 Code";
  };

  config = mkIf cfg.enable {
    homebrew.casks = ["t3-code"];
  };
}

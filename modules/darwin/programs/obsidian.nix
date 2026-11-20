{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.obsidian;
in {
  options.programs.obsidian = {
    enable = mkEnableOption "Obsidian";
  };

  config = mkIf cfg.enable {
    homebrew.casks = ["obsidian"];
  };
}

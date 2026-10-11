# Configuration for allowed unfree packages
{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "daisydisk"
      "fastscripts"
      "mochi"
      "obsidian-headless"
      "open-webui"
      "soundsource"
      "the-unarchiver"
    ];
}

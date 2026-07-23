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
      "graphite-cli"
      "graphite-cli-unwrapped"
      "mochi"
      "obsidian-headless"
      "open-webui"
      "roon-server"
      "soundsource"
      "the-unarchiver"
    ];
}

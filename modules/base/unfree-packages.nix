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
      "mochi"
      "plexmediaserver"
      "roon-server"
      "slack"
      "soundsource"
      "the-unarchiver"
      "zoom"
    ];
}

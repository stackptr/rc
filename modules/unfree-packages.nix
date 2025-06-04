# Configuration for allowed unfree packages
{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "chatgpt"
      "claude-code"
      "copilot-language-server"
      "cursor"
      "daisydisk"
      "fastscripts"
      "mochi"
      "plexmediaserver"
      "roon-server"
      "slack"
      "soundsource"
      "the-unarchiver"
      "whatsapp-for-mac"
      "zoom"
    ];
}

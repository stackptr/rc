{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [username];
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "chatgpt"
      "copilot-language-server"
      "cursor"
      "daisydisk"
      "mochi"
      "plexmediaserver"
      "roon-server"
      "slack"
      "soundsource"
      "the-unarchiver"
      "whatsapp-for-mac"
      "zoom"
    ];

  programs.zsh.enable = true;
}

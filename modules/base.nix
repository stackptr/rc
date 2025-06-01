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
      "claude-code"
      "copilot-language-server"
      "cursor"
      "daisydisk"
      "fastscripts"
      "mochi"
      "nova-editor"
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

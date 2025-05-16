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
      "plexmediaserver"
      "roon-server"
    ];

  programs.zsh.enable = true;
}

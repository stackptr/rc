{
  config,
  pkgs,
  username,
  ...
}: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [username];
  };

  programs.zsh.enable = true;
}

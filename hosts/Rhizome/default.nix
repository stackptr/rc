{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system.nix
  ];

  programs.zsh.enable = true;
}

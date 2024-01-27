{ config, pkgs, ... }: {
  imports = [
    ./system.nix
  ];

  environment.systemPackages =
    [ pkgs.vim
      pkgs.jq
    ];

  programs.zsh.enable = true;
}

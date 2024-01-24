{ config, pkgs, ... }: {
  imports = [
    ./system.nix
    ./wireless.nix
    ./services
  ];

  environment.systemPackages = with pkgs; [
    vim
    tailscale
  ];
  environment.pathsToLink = [ "/share/zsh" ];
}

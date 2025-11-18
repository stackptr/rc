{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./wireless.nix
    ./services
  ];

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

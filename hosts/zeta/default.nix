{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./wireless.nix
    ./services
    ./containers.nix
  ];

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

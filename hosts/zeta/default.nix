{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./wireless.nix
    ./services
  ];

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

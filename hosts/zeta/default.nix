{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system.nix
    ./wireless.nix
    ./services
    ./containers.nix
  ];

  environment.pathsToLink = ["/share/zsh"];
}

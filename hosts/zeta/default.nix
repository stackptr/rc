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
  ];

  environment.pathsToLink = ["/share/zsh"];
}

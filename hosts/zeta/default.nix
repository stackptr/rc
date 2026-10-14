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

# Deliberate syntax error to exercise the CI failure notification. Do not merge.
{ this is not valid nix

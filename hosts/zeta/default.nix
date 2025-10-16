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

  systemd.package = pkgs.systemd;

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

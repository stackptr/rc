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

  systemd.tmpfiles.rules = [
    "d /run/dbus 0755 root root - -"
  ];

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

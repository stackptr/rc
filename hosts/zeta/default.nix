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
  environment.systemPackages = with pkgs; [
    systemd
  ];

  services.dbus.implementation = "broker";

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

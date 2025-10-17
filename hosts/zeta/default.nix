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

  systemd.package = pkgs.systemdWithBridge;
  environment.systemPackages = with pkgs; [
    systemdWithBridge
  ];

  services.dbus.implementation = "broker";

  environment.pathsToLink = ["/share/zsh"];
  system.stateVersion = "23.11";
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./backup.nix
    ./web
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  networking.hostName = "nazar";

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.tailscale.enable = true;

  networking.firewall.allowedTCPPorts = [80 443 8448];

  system.stateVersion = "24.05";
}

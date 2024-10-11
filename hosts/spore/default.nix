{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  networking = {
    hostName = "spore";
    interfaces.eth0 = {
      ipv4.addresses = [
        {
          address = "74.48.202.251";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "74.48.202.1";
      interface = "eth0";
    };
    nameservers = ["8.8.8.8"];
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.tailscale.enable = true;

  system.stateVersion = "24.05";
}

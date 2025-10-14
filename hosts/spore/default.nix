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
    ./backup.nix
    ./services
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  networking = {
    hostName = "spore";
    enableIPv6 = false; # TODO: Avoid IPs auto added to interface after boot
    interfaces.eth0 = {
      useDHCP = false;
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

  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.trustedInterfaces = ["tailscale0"];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "24.05";
}

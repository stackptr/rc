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
    enableIPv6 = false; # TODO: Avoid IPs auto added to interface after boot
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "74.48.202.251";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2607:f130:0000:0173:0000:0000:71bb:96b0";
          prefixLength = 64;
        }
        {
          address = "2607:f130:0000:0173:0000:0000:59a9:2a5a";
          prefixLength = 64;
        }
        {
          address = "2607:f130:0000:0173:0000:0000:d7da:9af6";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "74.48.202.1";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "2607:f130:0000:0173::1";
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

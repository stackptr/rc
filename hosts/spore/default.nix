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
    ./services
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  networking = {
    hostName = "spore";
    enableIPv6 = false;
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

  boot.kernel.sysctl."vm.swappiness" = 1;

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # Stricter GC due to limited disk space (30 GB)
  nix.gc = {
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 7d";
  };

  nix.settings = {
    min-free = 1024 * 1024 * 1024; # 1 GB — trigger GC when free space drops below this
    max-free = 5 * 1024 * 1024 * 1024; # 5 GB — stop GC once this much space is free
  };

  system.stateVersion = "24.05";
}

{
  config,
  pkgs,
  ...
}: {
  age.secrets.userpassword.file = ./secrets/userpassword.age;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    mutableUsers = false;
    users.mu = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.userpassword.path;
      extraGroups = ["wheel" "docker"];
      shell = pkgs.zsh;
    };
    users.root.initialPassword = "password";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}

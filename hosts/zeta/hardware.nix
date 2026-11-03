{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];
  boot = {
    # nixos-hardware defaults to the Raspberry Pi vendor kernel, which Hydra
    # doesn't build, so every nixpkgs bump recompiled it in CI (~1h45m).
    # Mainline supports the Pi 4 and is in cache.nixos.org.
    kernelPackages = pkgs.linuxPackages;
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

  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
}

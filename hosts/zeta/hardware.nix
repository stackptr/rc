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
    # Keep nixos-hardware's default, the Raspberry Pi vendor kernel, even
    # though Hydra doesn't build it and CI compiles it on every nixpkgs bump
    # (~1h45m). Mainline doesn't fit the U-Boot on the firmware partition:
    # booti moves the Image to 0x200000, and from 6.18.57 mainline's
    # image_size (70 MiB) runs past fdt_addr_r (0x4700000), so U-Boot skips
    # the entry and boots an older generation instead. The vendor Image is
    # about 37 MB.
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

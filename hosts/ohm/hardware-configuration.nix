{modulesPath, ...}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
  fileSystems."/opt/data" = {
    device = "/dev/disk/by-id/scsi-0DO_Volume_storage";
    fsType = "ext4";
  };
  swapDevices = [
    {
      device = "/opt/data/swapfile";
      size = 8 * 1024;
    }
  ];
}

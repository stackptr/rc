{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./services
  ];

  boot.supportedFilesystems = ["ext4" "zfs"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot = false;

  fileSystems."/mnt/media" = {
    device = "zdata/media";
    fsType = "zfs";
  };
  fileSystems."/mnt/torrents" = {
    device = "zdata/torrents";
    fsType = "zfs";
  };

  networking.hostName = "glyph";
  networking.hostId = "e7bdc076"; # Ensure correct ZFS pool imported
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "24.05";
}

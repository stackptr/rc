{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.supportedFilesystems = ["ext4" "zfs"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot = false;

  fileSystems."/mnt/media" = {
    device = "zdata/media";
    fsType = "zfs";
  };

  networking.hostName = "glyph";
  networking.hostId = "e7bdc076"; # Ensure correct ZFS pool imported
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = false; # Only allow over Tailscale
    invalidUsers = [];
    shares = {
      Media = {
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "mu";
        "force group" = "users";
      };
    };
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };

  system.stateVersion = "24.05";
}

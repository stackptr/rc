{...}: {
  imports = [
    ./hardware.nix
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
  fileSystems."/mnt/archive" = {
    device = "zdata/archive";
    fsType = "zfs";
  };
  fileSystems."/mnt/torrents" = {
    device = "zdata/torrents";
    fsType = "zfs";
  };
  fileSystems."/mnt/unsorted" = {
    device = "zdata/unsorted";
    fsType = "zfs";
  };
  fileSystems."/mnt/backup" = {
    device = "zdata/backup";
    fsType = "zfs";
  };

  networking.hostName = "glyph";
  networking.hostId = "e7bdc076"; # Ensure correct ZFS pool imported
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
  };

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp5s0";
    cakeConfig = {
      Parent = "root";
      Bandwidth = "900M";
      RTTSec = "10ms";
      FlowIsolation = "triple-isolate";
      Preset = "diffserv3";
    };
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Beets library database (beets configured in home-manager)
  rc.backup.paths = ["/home/mu/.config/beets/library.db"];

  # Deliberately fail activation to test deploy-rs magic rollback
  system.activationScripts.test-rollback = ''
    echo "Testing deploy-rs rollback: this activation will now fail deliberately"
    exit 1
  '';

  system.stateVersion = "24.05";
}

{config, ...}: {
  imports = [
    ./hardware.nix
    ./services
  ];

  boot.supportedFilesystems = ["ext4" "zfs"];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot = false;
  # Cap ARC at 12 GiB. The default (all RAM but 1 GiB) let a full-library read
  # grow ARC to 23 GiB, and the kernel swapped services out rather than wait
  # for ARC to shrink: MemAvailable fell to 9% with 5 GiB swapped back in.
  boot.kernelParams = ["zfs.zfs_arc_max=${toString (12 * 1024 * 1024 * 1024)}"];

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
  fileSystems."/mnt/documents" = {
    device = "zdata/documents";
    fsType = "zfs";
  };

  users.users.colleen = {
    isSystemUser = true;
    group = "users";
    description = "Partner's Samba user";
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

  age.secrets.user-password.file = ./secrets/user-password.age;

  users.users.mu.hashedPasswordFile = config.age.secrets.user-password.path;

  # User secrets, read by home-manager through osConfig
  age.secrets = {
    aichat-env = {
      file = ../../home/secrets/aichat-env.age;
      owner = "mu";
    };
    # glyph's SSH client key (keys.clients.glyph) for root on spore and zeta
    ssh-client-key = {
      file = ./secrets/ssh-client-key.age;
      owner = "mu";
    };
  };

  system.stateVersion = "24.05";
}

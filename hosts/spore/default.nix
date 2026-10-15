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
          # CloudCone reassigned the VPS public IP (was 74.48.202.251/24).
          address = "182.255.82.149";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "182.255.82.1";
      interface = "eth0";
    };
    nameservers = ["8.8.8.8"];
    # nginx resolves every proxy_pass host when it loads its config, and
    # fails to start or reload if one doesn't resolve. Through MagicDNS
    # these names don't while tailscaled is down or restarting (as in the
    # 2026-10-11 lockout, or a deploy that upgrades it), and a failed nginx
    # takes id.zx.dev down with it. Tailnet IPs stay with a machine across
    # logins; if one changes, update it here.
    hosts = {
      "100.79.196.96" = ["glyph.note-iwato.ts.net"];
      "100.100.142.9" = ["zeta.note-iwato.ts.net"];
    };
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

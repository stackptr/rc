{
  config,
  pkgs,
  lib,
  ...
}: {
  fileSystems."/mnt/srv" = {
    device = "glyph.rove-duck.ts.net:/";
    fsType = "nfs4";
    options = [
      "_netdev"
      "x-systemd.automount" # Mount on first access, avoid boot hangs
      # Mount after Tailscale:
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
      "x-systemd.after=network-online.target"
      # Performance tuning from ChatGPT:
      "noatime"
      "rsize=1048576"
      "wsize=1048576"
      "hard"
      "timeo=600"
    ];
  };

  # Make sure network-online.target can actually be reached
  systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkDefault true;
}

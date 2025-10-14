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

  services.nginx.virtualHosts."srv.zx.dev" = {
    root = "/mnt/srv/www";
    forceSSL = true;
    useACMEHost = "zx.dev";

    locations."/" = {
      extraConfig = ''
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        charset utf-8;
      '';
    };
  };

  # Make sure network-online.target can actually be reached
  systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkDefault true;
}

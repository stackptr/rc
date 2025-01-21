{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./filebrowser.nix
    ./samba.nix
    ./torrents.nix
  ];
  users.groups.media = {};
  users.users.mu.extraGroups = ["media"];

  services.cockpit.enable = true;
  services.openssh.enable = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall = {
    allowedTCPPorts = [55002]; # Roon ARC
    allowedUDPPorts = [5353]; # mDNS
    allowedUDPPortRanges = [
      # Chromecast and Apple Airplay
      {
        from = 32768;
        to = 65535;
      }
    ];
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
}

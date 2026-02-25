{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./avahi.nix
    ./dns.nix
    ./filebrowser.nix
    ./jellyfin.nix
    ./nfs.nix
    ./prometheus.nix
    ./samba.nix
    ./torrents.nix
  ];
  users.groups.media = {};
  users.users.mu.extraGroups = ["media"];

  services.cockpit.enable = true;
  services.openssh.enable = true;
  services.roon-server = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall = {
    allowedTCPPorts = [
      554 # AirPlay streaming
      3689 # Digital Audio Access Protocol (DAAP)
      55002 # Roon ARC
    ];
    allowedUDPPorts = [
      554
      1900 # ssdp / Bonjour
    ];
    allowedUDPPortRanges = [
      # Apple Airplay
      {
        from = 6001;
        to = 6002;
      }
      # Bonjour
      {
        from = 5350;
        to = 5353;
      }
      # Chromecast and Apple Airplay
      {
        from = 32768;
        to = 65535;
      }
    ];
    # Dynamically allocated ports for Roon Bridge opened for local network
    extraCommands = ''
      iptables -A nixos-fw -p tcp --dport 30000:65535 -s 192.168.4.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p udp --dport 30000:65535 -s 192.168.4.0/24 -j nixos-fw-accept
    '';
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
}

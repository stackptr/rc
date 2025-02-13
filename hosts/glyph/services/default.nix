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
      iptables -A nixos-fw -p tcp -s 192.168.0.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p udp -s 192.168.0.0/24 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp -s 127.0.0.0/8 -j nixos-fw-accept
      iptables -A nixos-fw -p udp -s 127.0.0.0/8 -j nixos-fw-accept
    '';
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
}

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

  services.cockpit.enable = true;
  services.openssh.enable = true;
  services.plex = {
    enable = true;
    openFirewall = true;
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
}

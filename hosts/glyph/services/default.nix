{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./filebrowser.nix
    ./torrents.nix
  ];

  services.cockpit.enable = true;
  services.openssh.enable = true;
  services.plex.enable = true;
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
}

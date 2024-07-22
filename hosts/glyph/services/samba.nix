{
  config,
  pkgs,
  ...
}: {
  services.samba = let
    defaultShareOpts = {
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
    };
    mkShare = path: user: group:
      defaultShareOpts
      // {
        inherit path;
        "force user" = user;
        "force group" = group;
      };
  in {
    enable = true;
    securityType = "user";
    openFirewall = false; # Only allow over Tailscale
    invalidUsers = [];
    shares = {
      Media = mkShare "/mnt/media" config.services.plex.user config.services.plex.group;
      Torrents = mkShare "/mnt/torrents" config.services.transmission.user config.services.transmission.group;
    };
  };
}

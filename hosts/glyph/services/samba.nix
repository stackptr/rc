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
    shares = {
      Backup = mkShare "/mnt/backup" "mu" "users" // {"fruit:time machine" = "yes";};
      Media = mkShare "/mnt/media" config.services.plex.user config.services.plex.group;
      Stash = mkShare "/mnt/stash" "mu" "users";
      Torrents = mkShare "/mnt/torrents" config.services.transmission.user config.services.transmission.group;
      Unsorted = mkShare "/mnt/unsorted" "mu" "users";
    };
  in {
    enable = true;
    openFirewall = false; # Only allow over Tailscale
    settings = {
      global = {
        "invalid users" = [];
        securityType = "user";
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
    } // shares;
  };
}

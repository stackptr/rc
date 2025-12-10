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
      Archive = mkShare "/mnt/archive" "mu" "users";
      Backup = mkShare "/mnt/backup" "mu" "users" // {"fruit:time machine" = "yes";};
      Media = mkShare "/mnt/media" config.services.plex.user config.services.plex.group;
      Torrents = mkShare "/mnt/torrents" config.services.transmission.user config.services.transmission.group;
      Unsorted = mkShare "/mnt/unsorted" "mu" "users";
    };
  in {
    enable = true;
    openFirewall = false; # Only allow over Tailscale
    settings =
      {
        global = {
          "invalid users" = [];
          securityType = "user";
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:resource" = "file";
          "fruit:locking" = "netatalk";
          "fruit:encoding" = "native";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:veto_appledouble" = "no";
          "fruit:nfs_aces" = "no";
          "fruit:zero_file_id" = "yes";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "ea support" = "yes";
          "mangled names" = "no";
        };
      }
      // shares;
  };

  systemd.services.ensureSambaPermissions = {
    description = "Ensures correct permissions within Samba shares";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        defaultUsrGrp = "mu:users";
        plexUsrGrp = with config.services.plex; "${user}:${group}";
        transmissionUsrGrp = with config.services.transmission; "${user}:${group}";
      in [
        "${pkgs.coreutils}/bin/chown -R ${defaultUsrGrp} archive"
        "${pkgs.coreutils}/bin/chown -R ${defaultUsrGrp} backup"
        # N.B.: /mnt/media/Music is used by Roon, not Plex
        "${pkgs.coreutils}/bin/chown -R ${plexUsrGrp} media/Movies media/TV media/Video"
        "${pkgs.coreutils}/bin/chown -R ${defaultUsrGrp} media/Music"
        "${pkgs.coreutils}/bin/chown -R ${transmissionUsrGrp} torrents"
        "${pkgs.coreutils}/bin/chown -R ${defaultUsrGrp} unsorted"
      ];
      WorkingDirectory = "/mnt";
    };
  };

  systemd.timers.ensureSambaPermissions = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}

# Video Duplicate Finder's web UI: finds duplicate and near-duplicate videos and
# images in /mnt/archive. dupes.zx.dev on spore, behind Pocket ID.
_: let
  dataDir = "/var/lib/vdf";
  # The scanner's own log (ffmpeg and file errors), which VDF writes only to
  # log.txt next to its binary; Alloy ships it as {app="vdf"}. Outside
  # dataDir so Alloy's dynamic user can read it.
  logFile = "/var/log/vdf/log.txt";
in {
  virtualisation.oci-containers.containers.vdf = {
    # Upstream's :latest is a daily build; bump the release by hand
    image = "ghcr.io/0x90d/vdf-web:4.1.1";
    environment = {
      # Pocket ID on spore is the gate, as for AudioMuse
      VDF_WEB_AUTH = "false";
      # One line per entry with a <N> prefix, which conmon turns into the
      # journal priority; otherwise every line lands at 6 (stdout)
      Logging__Console__FormatterName = "systemd";
    };
    volumes = [
      # Same path inside, so results match filebrowser and Samba. Read-only:
      # duplicates are removed by hand elsewhere.
      "/mnt/archive:/mnt/archive:ro"
      "${dataDir}/config:/root/.config/VDF"
      "${dataDir}/state:/root/.local/state/VDF"
      "${logFile}:/app/log.txt"
    ];
    # tailscale0 is trusted, so no firewall rule
    ports = ["8087:8080"];
    extraOptions = [
      # Scans take idle CPU but yield to Jellyfin, Navidrome and Postgres
      "--cpu-shares=256"
    ];
  };

  systemd.services.podman-vdf.unitConfig.RequiresMountsFor = "/mnt/archive";

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root - -"
    "d ${dataDir}/config 0750 root root - -"
    "d ${dataDir}/state 0750 root root - -"
    "d /var/log/vdf 0755 root root - -"
    # The bind mount needs the file to exist before the container starts
    "f ${logFile} 0644 root root - -"
  ];

  # copytruncate keeps the inode the container's bind mount points at
  services.logrotate.settings.vdf = {
    files = logFile;
    frequency = "weekly";
    rotate = 4;
    copytruncate = true;
    compress = true;
    missingok = true;
    notifempty = true;
  };
}

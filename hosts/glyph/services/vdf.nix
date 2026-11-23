# Video Duplicate Finder's web UI: finds duplicate and near-duplicate videos and
# images in /mnt/archive. dupes.zx.dev on spore, behind Pocket ID.
_: let
  dataDir = "/var/lib/vdf";
in {
  virtualisation.oci-containers.containers.vdf = {
    # Upstream's :latest is a daily build; bump the release by hand
    image = "ghcr.io/0x90d/vdf-web:4.1.1";
    environment = {
      # Pocket ID on spore is the gate, as for AudioMuse
      VDF_WEB_AUTH = "false";
    };
    volumes = [
      # Same path inside, so results match filebrowser and Samba. Read-only:
      # duplicates are removed by hand elsewhere.
      "/mnt/archive:/mnt/archive:ro"
      "${dataDir}/config:/root/.config/VDF"
      "${dataDir}/state:/root/.local/state/VDF"
    ];
    # tailscale0 is trusted, so no firewall rule
    ports = ["8087:8080"];
    extraOptions = [
      # Scans take idle CPU but yield to Jellyfin, Navidrome and Postgres
      "--cpu-shares=256"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root - -"
    "d ${dataDir}/config 0750 root root - -"
    "d ${dataDir}/state 0750 root root - -"
  ];
}

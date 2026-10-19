{config, ...}: let
  # Upstream releases about weekly; bump deliberately rather than tracking latest
  image = "ghcr.io/neptunehub/audiomuse-ai:3.6.4";
  dataDir = "/var/lib/audiomuse";

  # Flask and the worker run the same image; SERVICE_TYPE picks the processes
  # supervisord starts. They coordinate through Postgres (the task queue and
  # restart requests live there), so neither needs to reach the other.
  mkContainer = serviceType: {
    inherit image;
    environment = {
      SERVICE_TYPE = serviceType;
      TZ = config.time.timeZone;
      # The socket directory, so `local all all trust` in db.nix applies and
      # no password is needed (the image's default one is ignored)
      POSTGRES_HOST = "/run/postgresql";
      POSTGRES_USER = "audiomuse";
      POSTGRES_DB = "audiomuse";
      # Plugins pip-install code at runtime
      PLUGINS_ENABLED = "false";
    };
    volumes = [
      "/run/postgresql:/run/postgresql"
      "${dataDir}/temp-${serviceType}:/app/temp_audio"
    ];
  };
in {
  # Everything else (Navidrome credentials, the oMLX provider and key, AudioMuse's
  # own login and API token) is set in the Setup Wizard and stored in the
  # database, which overrides environment variables after the first start.
  virtualisation.oci-containers.containers = {
    audiomuse-flask =
      mkContainer "flask"
      // {
        # open-terminal holds 8000; tailscale0 is trusted, so no firewall rule
        ports = ["8001:8000"];
      };
    audiomuse-worker = mkContainer "worker";
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root - -"
    "d ${dataDir}/temp-flask 0750 root root - -"
    "d ${dataDir}/temp-worker 0750 root root - -"
  ];

  systemd.services = let
    afterPostgres = {
      after = ["postgresql.target"];
      requires = ["postgresql.target"];
    };
  in {
    podman-audiomuse-flask = afterPostgres;
    podman-audiomuse-worker = afterPostgres;
  };
}

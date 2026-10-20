{
  config,
  lib,
  ...
}: let
  # Upstream releases about weekly; bump deliberately rather than tracking latest
  image = "ghcr.io/neptunehub/audiomuse-ai:3.6.4";
  dataDir = "/var/lib/audiomuse";

  # Each worker container runs one album job at a time, so analysis scales by
  # adding containers; they claim jobs from the same Postgres queue. The first
  # keeps its original name.
  workers = ["audiomuse-worker" "audiomuse-worker-2" "audiomuse-worker-3"];
  # Cores per worker. AudioMuse sizes its BLAS and ONNX thread pools from the
  # container's cgroup quota (cpu_budget.py), so this also sets their threads;
  # 3 x 7 leaves glyph 3 of its 24 cores even when all are busy.
  workerCpus = 7;

  # Flask and the worker run the same image; SERVICE_TYPE picks the processes
  # supervisord starts. They coordinate through Postgres (the task queue and
  # restart requests live there), so neither needs to reach the other.
  # Scratch space for the tracks a container is processing: temp-flask,
  # temp-worker, temp-worker-2, ...
  tempDir = name: "temp-${lib.removePrefix "audiomuse-" name}";

  mkContainer = serviceType: name: {
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
      # Honour X-Forwarded-* from spore's nginx (mix.zx.dev). Only seeds a new
      # database: an existing one keeps its app_config row, so flip that with
      # UPDATE app_config SET value = 'true' WHERE key = 'ENABLE_PROXY_FIX'
      ENABLE_PROXY_FIX = "true";
    };
    volumes = [
      "/run/postgresql:/run/postgresql"
      "${dataDir}/${tempDir name}:/app/temp_audio"
    ];
  };
in {
  # Everything else (Navidrome credentials, the oMLX provider and key, AudioMuse's
  # own login and API token) is set in the Setup Wizard and stored in the
  # database, which overrides environment variables after the first start.
  virtualisation.oci-containers.containers =
    {
      audiomuse-flask =
        mkContainer "flask" "audiomuse-flask"
        // {
          # open-terminal holds 8000; tailscale0 is trusted, so no firewall rule
          ports = ["8001:8000"];
        };
    }
    // lib.genAttrs workers (name:
      mkContainer "worker" name
      // {
        extraOptions = [
          "--cpus=${toString workerCpus}"
          # Analysis takes idle CPU but yields to Jellyfin, Navidrome and
          # Postgres (cpu.weight; the default is 1024). Set on the container:
          # its processes run in podman's cgroup, not the systemd unit's.
          "--cpu-shares=256"
        ];
      });

  systemd.tmpfiles.rules =
    ["d ${dataDir} 0750 root root - -"]
    ++ map (name: "d ${dataDir}/${tempDir name} 0750 root root - -") (["audiomuse-flask"] ++ workers);

  systemd.services = let
    afterPostgres = {
      after = ["postgresql.target"];
      requires = ["postgresql.target"];
    };
  in
    {
      podman-audiomuse-flask = afterPostgres;

      # AudioMuse has no metrics endpoint and its stats API needs the
      # admin-equivalent API token, so count analysed tracks straight from the
      # database for node_exporter's textfile collector (Homepage reads it).
      audiomuse-metrics =
        afterPostgres
        // {
          serviceConfig.Type = "oneshot";
          script = let
            # deploy-marker's directory, already passed to node_exporter
            textfileDir = "/var/lib/prometheus-node-exporter-textfile";
          in ''
            tracks=$(${config.services.postgresql.package}/bin/psql -h /run/postgresql \
              -U audiomuse -d audiomuse -tAc 'SELECT count(*) FROM score')
            mkdir -p ${textfileDir}
            echo "audiomuse_tracks_analysed $tracks" > ${textfileDir}/audiomuse.prom.tmp
            mv ${textfileDir}/audiomuse.prom.tmp ${textfileDir}/audiomuse.prom
          '';
        };
    }
    // lib.genAttrs (map (name: "podman-${name}") workers) (_: afterPostgres);

  systemd.timers.audiomuse-metrics = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
    };
  };
}

{config, ...}: let
  dataDir = "/var/lib/audiomuse";
in {
  age.secrets.audiomuse-env.file = ./../secrets/audiomuse-env.age;

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root - -"
    "d ${dataDir}/temp-flask 0755 root root - -"
    "d ${dataDir}/plugins-flask 0755 root root - -"
    "d ${dataDir}/temp-worker 0755 root root - -"
    "d ${dataDir}/plugins-worker 0755 root root - -"
  ];

  virtualisation.oci-containers.containers = {
    audiomuse-flask = {
      image = "ghcr.io/neptunehub/audiomuse-ai:latest";
      environmentFiles = [config.age.secrets.audiomuse-env.path];
      environment = {
        SERVICE_TYPE = "flask";
        TZ = config.time.timeZone;
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomuse";
        POSTGRES_HOST = "127.0.0.1";
        POSTGRES_PORT = "5432";
        TEMP_DIR = "/app/temp_audio";
      };
      volumes = [
        "${dataDir}/temp-flask:/app/temp_audio"
        "${dataDir}/plugins-flask:/app/plugin/installed"
      ];
      extraOptions = ["--network=host"];
    };

    audiomuse-worker = {
      image = "ghcr.io/neptunehub/audiomuse-ai:latest";
      environmentFiles = [config.age.secrets.audiomuse-env.path];
      environment = {
        SERVICE_TYPE = "worker";
        TZ = config.time.timeZone;
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomuse";
        POSTGRES_HOST = "127.0.0.1";
        POSTGRES_PORT = "5432";
        TEMP_DIR = "/app/temp_audio";
        NUMBA_CACHE_DIR = "/app/temp_audio/.numba_cache";
      };
      volumes = [
        "${dataDir}/temp-worker:/app/temp_audio"
        "${dataDir}/plugins-worker:/app/plugin/installed"
      ];
      extraOptions = ["--network=host"];
    };
  };

  systemd.services = {
    "podman-audiomuse-flask" = {
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
    };
    "podman-audiomuse-worker" = {
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
    };
  };

  networking.firewall.allowedTCPPorts = [8000];
}

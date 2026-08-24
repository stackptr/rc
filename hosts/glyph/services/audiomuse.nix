{
  config,
  pkgs,
  ...
}: {
  age.secrets.audiomuse-env.file = ./../secrets/audiomuse-env.age;

  systemd.tmpfiles.rules = [
    "d /var/lib/audiomuse 0755 root root - -"
    "d /var/lib/audiomuse/postgres 0700 root root - -"
    "d /var/lib/audiomuse/temp-flask 0755 root root - -"
    "d /var/lib/audiomuse/plugins-flask 0755 root root - -"
    "d /var/lib/audiomuse/temp-worker 0755 root root - -"
    "d /var/lib/audiomuse/plugins-worker 0755 root root - -"
  ];

  # Shared podman network so containers can reach each other by hostname.
  systemd.services.init-audiomuse-network = {
    description = "Create audiomuse podman network";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman network inspect audiomuse >/dev/null 2>&1 || \
        ${pkgs.podman}/bin/podman network create audiomuse
    '';
  };

  virtualisation.oci-containers.containers = {
    audiomuse-postgres = {
      image = "postgres:15-alpine";
      environmentFiles = [config.age.secrets.audiomuse-env.path];
      environment = {
        TZ = config.time.timeZone;
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomusedb";
      };
      volumes = ["/var/lib/audiomuse/postgres:/var/lib/postgresql/data"];
      extraOptions = [
        "--network=audiomuse"
        "--network-alias=postgres"
      ];
    };

    audiomuse-flask = {
      image = "ghcr.io/neptunehub/audiomuse-ai:latest";
      environmentFiles = [config.age.secrets.audiomuse-env.path];
      environment = {
        SERVICE_TYPE = "flask";
        TZ = config.time.timeZone;
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomusedb";
        POSTGRES_HOST = "postgres";
        POSTGRES_PORT = "5432";
        TEMP_DIR = "/app/temp_audio";
      };
      ports = ["8000:8000"];
      volumes = [
        "/var/lib/audiomuse/temp-flask:/app/temp_audio"
        "/var/lib/audiomuse/plugins-flask:/app/plugin/installed"
      ];
      extraOptions = ["--network=audiomuse"];
    };

    audiomuse-worker = {
      image = "ghcr.io/neptunehub/audiomuse-ai:latest";
      environmentFiles = [config.age.secrets.audiomuse-env.path];
      environment = {
        SERVICE_TYPE = "worker";
        TZ = config.time.timeZone;
        POSTGRES_USER = "audiomuse";
        POSTGRES_DB = "audiomusedb";
        POSTGRES_HOST = "postgres";
        POSTGRES_PORT = "5432";
        TEMP_DIR = "/app/temp_audio";
      };
      volumes = [
        "/var/lib/audiomuse/temp-worker:/app/temp_audio"
        "/var/lib/audiomuse/plugins-worker:/app/plugin/installed"
      ];
      extraOptions = ["--network=audiomuse"];
    };
  };

  # Ensure network exists before any container starts, and postgres before app containers.
  systemd.services = {
    "podman-audiomuse-postgres" = {
      after = ["init-audiomuse-network.service"];
      requires = ["init-audiomuse-network.service"];
    };
    "podman-audiomuse-flask" = {
      after = ["init-audiomuse-network.service" "podman-audiomuse-postgres.service"];
      requires = ["init-audiomuse-network.service" "podman-audiomuse-postgres.service"];
    };
    "podman-audiomuse-worker" = {
      after = ["init-audiomuse-network.service" "podman-audiomuse-postgres.service"];
      requires = ["init-audiomuse-network.service" "podman-audiomuse-postgres.service"];
    };
  };

  networking.firewall.allowedTCPPorts = [8000];
}

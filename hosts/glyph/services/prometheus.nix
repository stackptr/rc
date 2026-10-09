{
  config,
  pkgs,
  ...
}: let
  # Copy instance into host, so metrics and Loki logs for the same machine
  # share a label name ({host="glyph"} works in both PromQL and LogQL).
  withHostLabel = job:
    job
    // {
      relabel_configs =
        (job.relabel_configs or [])
        ++ [
          {
            source_labels = ["instance"];
            target_label = "host";
          }
        ];
    };
in {
  services.prometheus = {
    enable = true;
    port = 9099;
    # Default is 15d. The TSDB is well under 1 GB, and longer history lets
    # agents compare against last month when looking for regressions.
    retentionTime = "90d";
    # Accepts OTLP metrics pushes at /api/v1/otlp/v1/metrics (Open WebUI).
    extraFlags = ["--web.enable-otlp-receiver"];
    exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = ["systemd"];
    };
    exporters.zfs = {
      enable = true;
      port = 9134;
    };
    exporters.postgres = {
      enable = true;
      port = 9187;
      dataSourceName = "user=mu database=postgres host=/var/run/postgresql sslmode=disable";
    };
    exporters.smartctl = {
      enable = true;
      port = 9633;
    };
    scrapeConfigs = map withHostLabel [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
            ];
            labels.instance = "glyph";
          }
          {
            targets = [
              "spore.note-iwato.ts.net:9100"
            ];
            labels.instance = "spore";
          }
          {
            targets = [
              "zeta.note-iwato.ts.net:9100"
            ];
            labels.instance = "zeta";
          }
          {
            # nix-darwin; see hosts/Stroma/monitoring.nix
            targets = [
              "stroma.note-iwato.ts.net:9100"
            ];
            labels.instance = "stroma";
          }
        ];
      }
      {
        # Apple Silicon metrics from mactop on Stroma (hosts/Stroma/monitoring.nix).
        job_name = "mactop";
        static_configs = [
          {
            targets = ["stroma.note-iwato.ts.net:9101"];
            labels.instance = "stroma";
          }
        ];
      }
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.zfs.port}"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "postgres";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.postgres.port}"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.smartctl.port}"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "nginx";
        static_configs = [
          {
            targets = [
              "spore.note-iwato.ts.net:9113"
            ];
            labels.instance = "spore";
          }
        ];
      }
      {
        job_name = "navidrome";
        static_configs = [
          {
            targets = [
              "localhost:4533"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.port}"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "loki";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.loki.configuration.server.http_listen_port}"
            ];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "coredns";
        static_configs = [
          {
            targets = ["localhost:9153"];
            labels.instance = "glyph";
          }
        ];
      }
      {
        job_name = "ntfy";
        static_configs = [
          {
            targets = [config.services.ntfy-sh.settings.metrics-listen-http];
            labels.instance = "glyph";
          }
        ];
      }
      {
        # Gatus watchdog on zeta (hosts/zeta/services/gatus.nix).
        job_name = "gatus";
        static_configs = [
          {
            targets = ["zeta.note-iwato.ts.net:8080"];
            labels.instance = "zeta";
          }
        ];
      }
    ];
  };
}

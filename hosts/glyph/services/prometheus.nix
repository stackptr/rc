{
  config,
  pkgs,
  ...
}: {
  services.prometheus = {
    enable = true;
    port = 9099;
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
    scrapeConfigs = [
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
    ];
  };
}

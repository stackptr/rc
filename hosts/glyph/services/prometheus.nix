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
              "spore.rove-duck.ts.net:9100"
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
          }
        ];
      }
    ];
  };
}

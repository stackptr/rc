# Shared node exporter flags for every host that enables it. Each host still
# sets enable, port and enabledCollectors itself.
{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.prometheus.exporters.node.enable {
    services.prometheus.exporters.node.extraFlags = [
      # node_systemd_service_restart_total: automatic restarts (NRestarts),
      # which makes crash loops visible.
      "--collector.systemd.enable-restarts-metrics"
      # node_systemd_unit_start_time_seconds: when each unit last started.
      "--collector.systemd.enable-start-time-metrics"
    ];
  };
}

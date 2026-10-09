# Shared node exporter flags. Each host still sets enable, port and
# enabledCollectors itself; the flags have no effect where it's disabled.
# Don't gate this on `exporters.node.enable`: `exporters.node` is a submodule
# option, so an mkIf reading its own enable recurses infinitely.
{
  services.prometheus.exporters.node.extraFlags = [
    # node_systemd_service_restart_total: automatic restarts (NRestarts),
    # which makes crash loops visible.
    "--collector.systemd.enable-restarts-metrics"
    # node_systemd_unit_start_time_seconds: when each unit last started.
    "--collector.systemd.enable-start-time-metrics"
  ];
}

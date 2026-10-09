# Grafana-managed alert rules, provisioned so they live in the flake rather
# than only in Grafana's database. All rules route to the default policy
# (Slack). Datasource UIDs are pinned in ./grafana.nix.
_: let
  prometheus = "PBFA97CFB590B2093";
  loki = "P8E80F9AEF21F6940";

  # Hosts that ship journald logs to Loki via Alloy.
  logHosts = ["glyph" "spore" "zeta"];

  # Build a rule: query A (instant) compared by threshold expression C.
  mkRule = {
    uid,
    title,
    expr,
    summary,
    datasourceUid ? prometheus,
    evaluator ? {
      type = "gt";
      params = [0];
    },
    for ? "5m",
    noDataState ? "OK",
    # A query error (datasource down) is not this rule's condition. Leaving
    # it at "Error" makes every rule raise a label-less DatasourceError named
    # after itself ("ZFS pool [no value] is not ONLINE"). Datasource outages
    # are covered by the *-unreachable rules below and by Gatus on zeta.
    execErrState ? "OK",
    severity ? "warning",
  }: {
    inherit uid title for noDataState execErrState;
    condition = "C";
    isPaused = false;
    labels.severity = severity;
    annotations.summary = summary;
    data = [
      {
        refId = "A";
        inherit datasourceUid;
        relativeTimeRange = {
          from = 600;
          to = 0;
        };
        model =
          {
            refId = "A";
            inherit expr;
          }
          // (
            if datasourceUid == loki
            then {queryType = "instant";}
            else {instant = true;}
          );
      }
      {
        refId = "C";
        datasourceUid = "__expr__";
        model = {
          refId = "C";
          type = "threshold";
          expression = "A";
          conditions = [{inherit evaluator;}];
        };
      }
    ];
  };

  systemRules = [
    (mkRule {
      uid = "systemd-unit-failed";
      title = "Systemd unit failed";
      expr = ''node_systemd_unit_state{state="failed", name=~".+\\.service"} == 1'';
      summary = "{{ $labels.name }} is in failed state on {{ $labels.instance }}";
      for = "2m";
    })
    (mkRule {
      uid = "scrape-target-down";
      title = "Scrape target down";
      expr = "up == 0";
      summary = "Prometheus cannot scrape job {{ $labels.job }} on {{ $labels.instance }}";
      severity = "critical";
    })
    (mkRule {
      uid = "filesystem-full";
      title = "Filesystem nearly full";
      expr = ''100 * (1 - node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|overlay|squashfs|nfs.*", mountpoint!="/nix/store"} / node_filesystem_size_bytes) > 90'';
      summary = "{{ $labels.mountpoint }} on {{ $labels.instance }} is {{ printf \"%.0f\" $values.A.Value }}% full";
      for = "15m";
    })
    (mkRule {
      uid = "memory-low";
      title = "Memory low";
      expr = "100 * node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 10";
      summary = "{{ $labels.instance }} has {{ printf \"%.0f\" $values.A.Value }}% memory available";
      for = "10m";
    })
    (mkRule {
      uid = "backup-stale";
      title = "Backup timer stale";
      expr = ''time() - node_systemd_timer_last_trigger_seconds{name=~"restic-backups-.+\\.timer"} > 26 * 3600'';
      summary = "{{ $labels.name }} on {{ $labels.instance }} has not triggered in over 26h";
    })
    (mkRule {
      uid = "systemd-unit-restarting";
      title = "Systemd unit restart loop";
      # Restart= keeps a crash-looping unit out of the failed state, so the
      # failed-unit rule never sees it.
      expr = "increase(node_systemd_service_restart_total[15m]) > 3";
      summary = "{{ $labels.name }} on {{ $labels.instance }} restarted {{ printf \"%.0f\" $values.A.Value }} times in 15m";
    })
  ];

  storageRules = [
    (mkRule {
      uid = "zfs-pool-unhealthy";
      title = "ZFS pool unhealthy";
      # zfs_exporter: 0 = ONLINE; anything else is degraded, faulted, etc.
      expr = "zfs_pool_health != 0";
      summary = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} is not ONLINE";
      severity = "critical";
      for = "1m";
    })
    (mkRule {
      uid = "zfs-pool-full";
      title = "ZFS pool nearly full";
      expr = "100 * zfs_pool_allocated_bytes / zfs_pool_size_bytes > 85";
      summary = "ZFS pool {{ $labels.pool }} is {{ printf \"%.0f\" $values.A.Value }}% allocated";
      for = "1h";
    })
    (mkRule {
      uid = "smart-failing";
      title = "SMART health check failing";
      expr = "smartctl_device_smart_status != 1";
      summary = "Disk {{ $labels.device }} on {{ $labels.instance }} is failing its SMART health check";
      severity = "critical";
    })
    (mkRule {
      uid = "disk-hot";
      title = "Disk temperature high";
      # SATA drives; NVMe runs hotter and has its own threshold below.
      expr = ''smartctl_device_temperature{temperature_type="current", device!~"nvme.*"} > 50'';
      summary = "Disk {{ $labels.device }} on {{ $labels.instance }} is at {{ $values.A.Value }}°C";
      for = "15m";
    })
    # NVMe drives report no smart_status; health comes from these instead.
    (mkRule {
      uid = "nvme-critical-warning";
      title = "NVMe critical warning";
      expr = "smartctl_device_critical_warning != 0";
      summary = "NVMe {{ $labels.device }} on {{ $labels.instance }} reports critical warning bits {{ $values.A.Value }}";
      severity = "critical";
      for = "1m";
    })
    (mkRule {
      uid = "nvme-media-errors";
      title = "NVMe media errors";
      expr = "increase(smartctl_device_media_errors[1h]) > 0";
      summary = "NVMe {{ $labels.device }} on {{ $labels.instance }} logged new unrecovered media errors in the last hour";
      for = "0s";
    })
    (mkRule {
      uid = "nvme-wear";
      title = "NVMe wear high";
      expr = "smartctl_device_percentage_used > 80";
      summary = "NVMe {{ $labels.device }} on {{ $labels.instance }} has used {{ $values.A.Value }}% of its rated endurance";
      for = "1h";
    })
    (mkRule {
      uid = "nvme-hot";
      title = "NVMe temperature high";
      expr = ''smartctl_device_temperature{temperature_type="current", device=~"nvme.*"} > 70'';
      summary = "NVMe {{ $labels.device }} on {{ $labels.instance }} is at {{ $values.A.Value }}°C";
      for = "15m";
    })
  ];

  # One rule per host so the alert names the silent host. `or vector(0)`
  # keeps the series present when a host sends nothing at all.
  logRules = map (host:
    mkRule {
      uid = "log-ingest-${host}";
      title = "Log ingestion stalled (${host})";
      datasourceUid = loki;
      expr = ''sum(count_over_time({host="${host}"}[30m])) or vector(0)'';
      evaluator = {
        type = "lt";
        params = [1];
      };
      summary = "Loki has received no logs from ${host} in 30m; check alloy.service on ${host}";
      noDataState = "Alerting";
    })
  logHosts;

  # Health of the pipeline itself, from Alloy's and Grafana's own metrics.
  pipelineRules = [
    (mkRule {
      uid = "alloy-dropping-logs";
      title = "Alloy dropping log entries";
      expr = "sum by (instance) (increase(loki_write_dropped_entries_total[15m])) > 0";
      summary = "Alloy on {{ $labels.instance }} dropped {{ printf \"%.0f\" $values.A.Value }} log entries in 15m; Loki is rejecting or unreachable";
      for = "0s";
    })
    (mkRule {
      uid = "grafana-rule-eval-failures";
      title = "Grafana alert rules failing to evaluate";
      # Rules here use execErrState = OK, so a broken query is otherwise
      # silent; this catches it.
      expr = "sum(increase(grafana_alerting_rule_evaluation_failures_total[10m])) > 0";
      summary = "Grafana had {{ printf \"%.0f\" $values.A.Value }} alert rule evaluation failures in 10m; check Alerting > Alert rules for errors";
      for = "10m";
    })
  ];

  # The only rules that alert on query errors: one per datasource, so an
  # outage produces one accurately named alert instead of one per rule.
  datasourceRules = [
    (mkRule {
      uid = "prometheus-empty";
      title = "Prometheus unreachable or empty";
      expr = "count(up)";
      evaluator = {
        type = "lt";
        params = [1];
      };
      summary = "Prometheus on glyph is unreachable or has no up series; other Prometheus-based alerts can't fire";
      noDataState = "Alerting";
      execErrState = "Alerting";
      severity = "critical";
    })
    (mkRule {
      uid = "loki-unreachable";
      title = "Loki unreachable or empty";
      datasourceUid = loki;
      expr = ''sum(count_over_time({host=~".+"}[10m])) or vector(0)'';
      evaluator = {
        type = "lt";
        params = [1];
      };
      summary = "Loki on glyph is unreachable or has received no logs from any host in 10m; log-based alerts can't fire";
      noDataState = "Alerting";
      execErrState = "Alerting";
      severity = "critical";
    })
  ];

  # Built from nginx JSON access logs; see services/web/default.nix.
  webRules = [
    (mkRule {
      uid = "nginx-5xx";
      title = "nginx 5xx responses";
      datasourceUid = loki;
      expr = ''sum by (vhost) (count_over_time({host="spore", app="nginx_access"} | json vhost, status | status >= 500 [10m]))'';
      evaluator = {
        type = "gt";
        params = [10];
      };
      summary = "{{ $labels.vhost }} returned {{ $values.A.Value }} 5xx responses in 10m";
    })
  ];

  mkGroup = name: rules: {
    orgId = 1;
    inherit name rules;
    folder = "Alerts";
    interval = "1m";
  };
in {
  services.grafana.provision.alerting.rules.settings = {
    apiVersion = 1;
    groups = [
      (mkGroup "hosts" systemRules)
      (mkGroup "storage" storageRules)
      (mkGroup "telemetry" (logRules ++ datasourceRules ++ pipelineRules))
      (mkGroup "web" webRules)
    ];
  };
}

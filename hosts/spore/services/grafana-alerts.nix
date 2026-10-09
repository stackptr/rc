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
    severity ? "warning",
  }: {
    inherit uid title for noDataState;
    condition = "C";
    execErrState = "Error";
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
      expr = ''smartctl_device_temperature{temperature_type="current"} > 50'';
      summary = "Disk {{ $labels.device }} on {{ $labels.instance }} is at {{ $values.A.Value }}°C";
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

  # Fires when the Prometheus datasource returns nothing, e.g. the TSDB
  # stopped ingesting. An unreachable Prometheus surfaces as DatasourceError.
  prometheusRules = [
    (mkRule {
      uid = "prometheus-empty";
      title = "Prometheus has no scrape data";
      expr = "count(up)";
      evaluator = {
        type = "lt";
        params = [1];
      };
      summary = "Prometheus on glyph returned no up series";
      noDataState = "Alerting";
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
      (mkGroup "telemetry" (logRules ++ prometheusRules))
      (mkGroup "web" webRules)
    ];
  };
}

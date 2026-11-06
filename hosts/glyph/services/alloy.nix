_: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal_priority"]
        target_label  = "priority"
      }
      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "app"
      }
    }

    loki.source.journal "systemd" {
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.local.receiver]
    }

    // CPU, memory and disk I/O per systemd unit and slice, from cgroups.
    // Prometheus scrapes it from Alloy's own server (the cadvisor job in
    // prometheus.nix). docker_only limits it to the root cgroup and the
    // prefixes below, which leaves out user sessions and scopes; there's no
    // Docker here, so nothing else matches. /machine.slice holds podman's
    // containers, whose podman-<name>.service units only hold conmon.
    prometheus.exporter.cadvisor "units" {
      docker_only                 = true
      raw_cgroup_prefix_allowlist = ["/system.slice/", "/agents.slice", "/machine.slice/"]
      enabled_metrics             = ["cpu", "memory", "diskIO"]
      store_container_labels      = false
    }

    loki.write "local" {
      endpoint {
        url = "http://localhost:3100/loki/api/v1/push"
      }
      external_labels = {
        host = "glyph",
      }
    }
  '';
}

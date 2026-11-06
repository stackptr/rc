_: {
  services.alloy = {
    enable = true;
    # Prometheus on glyph scrapes Alloy's own metrics over the tailnet.
    extraFlags = ["--server.http.listen-addr=0.0.0.0:12345"];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [12345];

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
      forward_to    = [loki.write.remote.receiver]
    }

    // CPU, memory and disk I/O per systemd unit, from cgroups; Prometheus
    // on glyph scrapes it from Alloy's server as the cadvisor job (see
    // hosts/glyph/services/alloy.nix). docker_only limits it to the root
    // cgroup and the allowlisted prefix, which leaves out user sessions.
    prometheus.exporter.cadvisor "units" {
      docker_only                 = true
      raw_cgroup_prefix_allowlist = ["/system.slice/"]
      enabled_metrics             = ["cpu", "memory", "diskIO"]
      store_container_labels      = false
    }

    loki.write "remote" {
      endpoint {
        url = "http://glyph.note-iwato.ts.net:3100/loki/api/v1/push"
      }
      external_labels = {
        host = "zeta",
      }
    }
  '';
}

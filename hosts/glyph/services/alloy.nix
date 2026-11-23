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

    // Video Duplicate Finder's scanner log (vdf.nix). Lines are
    // "HH:mm:ss => [ERROR] text", tagged only for warnings and errors, plus a
    // blank line and a dashed banner at the start of each scan.
    local.file_match "vdf" {
      path_targets = [{"__path__" = "/var/log/vdf/log.txt", "app" = "vdf"}]
    }

    loki.source.file "vdf" {
      targets    = local.file_match.vdf.targets
      forward_to = [loki.process.vdf.receiver]
    }

    loki.process "vdf" {
      stage.drop {
        expression = "^\\s*$"
      }

      // A message with newlines (an exception) continues on lines without
      // the timestamp
      stage.multiline {
        firstline     = "^(\\d{2}:\\d{2}:\\d{2} => |-{60} )"
        max_wait_time = "3s"
      }

      stage.regex {
        expression = "^\\S+ => \\[(?P<level>ERROR|WARNING)\\] "
      }

      // The journald priority numbers, so {priority=~"[0-3]"} finds VDF's
      // scan errors too
      stage.template {
        source   = "priority"
        template = "{{ if eq .level \"ERROR\" }}3{{ else if eq .level \"WARNING\" }}4{{ else }}6{{ end }}"
      }

      stage.labels {
        values = {priority = ""}
      }

      stage.label_drop {
        values = ["filename"]
      }

      forward_to = [loki.write.local.receiver]
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

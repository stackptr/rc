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
        source_labels = ["__journal__priority"]
        target_label  = "priority"
      }
      rule {
        source_labels = ["__journal__syslog_identifier"]
        target_label  = "app"
      }
    }

    loki.source.journal "systemd" {
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.local.receiver]
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

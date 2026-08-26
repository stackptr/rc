_: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "systemd" {
      forward_to = [loki.relabel.journal.receiver]
    }

    loki.relabel "journal" {
      forward_to = [loki.write.remote.receiver]

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

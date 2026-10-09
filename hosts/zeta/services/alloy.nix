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

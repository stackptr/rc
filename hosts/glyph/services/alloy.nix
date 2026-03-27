_: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "systemd" {
      forward_to = [loki.write.local.receiver]
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

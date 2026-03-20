_: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    loki.source.journal "systemd" {
      forward_to = [loki.write.remote.receiver]
    }

    loki.write "remote" {
      endpoint {
        url = "http://glyph.rove-duck.ts.net:3100/loki/api/v1/push"
      }
      external_labels = {
        host = "zeta",
      }
    }
  '';
}

# Out-of-band watchdog for the monitoring stack. Grafana (spore) keeps its
# database on glyph, and Prometheus and Loki run on glyph, so an outage there
# silences every Grafana alert. Gatus probes them from zeta and posts to
# Slack directly. Grafana in turn alerts if zeta's node exporter goes away.
{config, ...}: let
  glyph = "glyph.note-iwato.ts.net";
  spore = "spore.note-iwato.ts.net";

  alert = description: {
    type = "custom";
    inherit description;
    failure-threshold = 3;
    success-threshold = 2;
    send-on-resolved = true;
    minimum-reminder-interval = "4h";
  };

  mkEndpoint = {
    name,
    group,
    url,
    conditions,
    description,
  }: {
    inherit name group url conditions;
    interval = "1m";
    alerts = [(alert description)];
  };
in {
  age.secrets.gatus-env.file = ./../secrets/gatus-env.age;

  services.gatus = {
    enable = true;
    # Holds SLACK_BOT_TOKEN, the same bot Grafana posts with.
    environmentFile = config.age.secrets.gatus-env.path;
    settings = {
      web.port = 8080;
      metrics = true;
      # Default in-memory storage; avoids SD card writes. History resets on
      # restart, which is fine for a watchdog.

      alerting.custom = {
        url = "https://slack.com/api/chat.postMessage";
        method = "POST";
        headers = {
          Authorization = "Bearer \${SLACK_BOT_TOKEN}";
          Content-Type = "application/json; charset=utf-8";
        };
        body = builtins.toJSON {
          channel = "#updates";
          username = "Gatus (zeta)";
          icon_emoji = ":rotating_light:";
          text = "[ALERT_TRIGGERED_OR_RESOLVED] [ENDPOINT_GROUP]/[ENDPOINT_NAME]: [ALERT_DESCRIPTION]";
        };
        placeholders.ALERT_TRIGGERED_OR_RESOLVED = {
          TRIGGERED = "[FIRING]";
          RESOLVED = "[RESOLVED]";
        };
      };

      endpoints = [
        (mkEndpoint {
          name = "reachable";
          group = "glyph";
          url = "tcp://${glyph}:22";
          conditions = ["[CONNECTED] == true"];
          description = "glyph is unreachable over the tailnet; Prometheus, Loki and Grafana's database are down with it";
        })
        (mkEndpoint {
          name = "postgres";
          group = "glyph";
          url = "tcp://${glyph}:5432";
          conditions = ["[CONNECTED] == true"];
          description = "PostgreSQL on glyph is not accepting connections; Grafana, pocket-id and others depend on it";
        })
        (mkEndpoint {
          name = "prometheus";
          group = "glyph";
          # An instant query only returns samples from the last 5m, so an empty
          # result means scraping or ingestion has stalled.
          url = "http://${glyph}:9099/api/v1/query?query=up";
          conditions = [
            "[STATUS] == 200"
            "len([BODY].data.result) > 0"
          ];
          description = "Prometheus is down or has no samples from the last 5m";
        })
        (mkEndpoint {
          name = "loki";
          group = "glyph";
          # zeta's own journal shipped through Alloy proves end-to-end ingestion.
          url = "http://${glyph}:3100/loki/api/v1/query?query=sum(count_over_time(%7Bhost%3D%22zeta%22%7D%5B10m%5D))";
          conditions = [
            "[STATUS] == 200"
            "len([BODY].data.result) > 0"
          ];
          description = "Loki is down or has received no logs from zeta in 10m";
        })
        (mkEndpoint {
          name = "reachable";
          group = "spore";
          url = "tcp://${spore}:22";
          conditions = ["[CONNECTED] == true"];
          description = "spore is unreachable over the tailnet; Grafana alerting is down with it";
        })
        (mkEndpoint {
          name = "grafana";
          group = "spore";
          url = "https://grafana.zx.dev/api/health";
          conditions = [
            "[STATUS] == 200"
            "[BODY].database == ok"
          ];
          description = "Grafana is down or cannot reach its database; Grafana alerts will not fire";
        })
      ];
    };
  };

  # Status page, reachable over the tailnet only.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.gatus.settings.web.port];
}

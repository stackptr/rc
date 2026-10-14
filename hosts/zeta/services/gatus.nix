# Out-of-band watchdog for the monitoring stack. Grafana, its database,
# Prometheus and Loki all run on glyph, so an outage there silences every
# Grafana alert. Gatus probes them from zeta and posts to
# Slack directly. Grafana in turn alerts if zeta's node exporter goes away.
{
  config,
  pkgs,
  ...
}: let
  glyph = "glyph.note-iwato.ts.net";
  spore = "spore.note-iwato.ts.net";
  port = config.services.gatus.settings.web.port;

  # Tailscale machines that must never expire: logins to the tailnet go
  # through id.zx.dev, which needs spore and glyph on it, so an expired
  # server can lock every device out (as on 2026-10-11).
  servers = ["glyph" "spore" "zeta" "stroma"];

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
    interval ? "1m",
    headers ? {},
  }: {
    inherit name group url conditions interval headers;
    alerts = [(alert description)];
  };
in {
  age.secrets.gatus-env.file = ./../secrets/gatus-env.age;

  services.gatus = {
    enable = true;
    # Holds SLACK_BOT_TOKEN, the same bot Grafana posts with;
    # GATUS_EXTERNAL_TOKEN, which tailscale-key-expiry pushes results with;
    # and TS_API_CLIENT_ID/TS_API_CLIENT_SECRET, a Tailscale OAuth client
    # with the devices:core:read scope (OAuth clients don't expire; API
    # keys do).
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
          description = "spore is unreachable over the tailnet; *.zx.dev, including grafana.zx.dev, is down with it";
        })
        (mkEndpoint {
          name = "grafana";
          group = "glyph";
          # Through spore's nginx, so this also fails when the proxy does.
          url = "https://grafana.zx.dev/api/health";
          conditions = [
            "[STATUS] == 200"
            "[BODY].database == ok"
          ];
          description = "Grafana is down or cannot reach its database; Grafana alerts will not fire";
        })
        (mkEndpoint {
          name = "certificate";
          group = "spore";
          # *.zx.dev, zx.dev and cjohns.com share one ACME cert on spore.
          # NixOS renews at 30 days left, so under 21 means renewal has
          # been failing for over a week.
          url = "https://zx.dev";
          interval = "1h";
          conditions = ["[CERTIFICATE_EXPIRATION] > 504h"];
          description = "The zx.dev certificate expires in under 21 days; check acme-zx.dev.service on spore";
        })

        # Public sites, checked through their public URLs, so a failure can
        # be DNS, the certificate, spore's nginx or the backend on glyph.
        (mkEndpoint {
          name = "jellyfin";
          group = "sites";
          url = "https://jellyfin.zx.dev/health";
          conditions = [
            "[STATUS] == 200"
            "[BODY] == Healthy"
          ];
          description = "jellyfin.zx.dev is down or unhealthy; check jellyfin.service on glyph";
        })
        (mkEndpoint {
          name = "navidrome";
          group = "sites";
          url = "https://music.zx.dev/ping";
          conditions = ["[STATUS] == 200"];
          description = "music.zx.dev (Navidrome) is down; check navidrome.service on glyph";
        })
        (mkEndpoint {
          name = "open-webui";
          group = "sites";
          url = "https://chat.zx.dev/health";
          conditions = [
            "[STATUS] == 200"
            "[BODY].status == true"
          ];
          description = "chat.zx.dev (Open WebUI) is down; check open-webui.service on glyph";
        })
        (mkEndpoint {
          name = "freshrss";
          group = "sites";
          # Unauthenticated self-test of the Google Reader API that Reeder
          # syncs through. It answers FAIL unless it can read an Authorization
          # header, so this also catches a proxy that drops it. FreshRSS logs
          # a warning per call, hence the longer interval.
          url = "https://rss.zx.dev/api/greader.php/check/compatibility";
          headers.Authorization = "GoogleLogin auth=test/1";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY] == PASS"
          ];
          description = "rss.zx.dev (FreshRSS) API is down or failing its self-test; Reeder can't sync. Check phpfpm-freshrss.service and nginx on glyph";
        })
        (mkEndpoint {
          name = "pocket-id";
          group = "sites";
          # Every requireAuth site and Grafana's login depend on this.
          url = "https://id.zx.dev/.well-known/openid-configuration";
          conditions = [
            "[STATUS] == 200"
            "[BODY].issuer == https://id.zx.dev"
          ];
          description = "id.zx.dev (Pocket ID) is down; logins to Grafana and every auth-protected site fail. Check pocket-id.service on spore and its database on glyph";
        })
        (mkEndpoint {
          name = "models";
          group = "sites";
          # spore proxies / to oMLX's admin UI on Stroma. The UI loads without
          # an API key, so this needs no credentials.
          url = "https://models.zx.dev/";
          conditions = ["[STATUS] == 200"];
          description = "models.zx.dev (oMLX) is down; check oMLX on Stroma (it may be asleep or restarting) and the tailnet link from spore";
        })
      ];

      # Results pushed by tailscale-key-expiry below; Gatus conditions can't
      # compare dates in a response body.
      external-endpoints = [
        {
          name = "key-expiry";
          group = "tailscale";
          token = "\${GATUS_EXTERNAL_TOKEN}";
          # Fails when the hourly push stops arriving
          heartbeat.interval = "3h";
          alerts = [
            ((alert "A Tailscale node key expires within 14 days or has expired, or a server has key expiry enabled; the error on the status page names the machines. Renew or disable expiry at login.tailscale.com while id.zx.dev still works")
              // {
                failure-threshold = 1;
                minimum-reminder-interval = "24h";
              })
          ];
        }
      ];
    };
  };

  # Hourly: every machine whose key expires within 14 days (or has expired),
  # and any server with expiry enabled at all. Uses the public Tailscale API,
  # so it works while the tailnet doesn't.
  systemd.services.tailscale-key-expiry = {
    description = "Report Tailscale node key expiry to Gatus";
    wants = ["network-online.target"];
    after = ["network-online.target" "gatus.service"];
    path = [pkgs.curl pkgs.jq pkgs.coreutils];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.age.secrets.gatus-env.path;
    };
    script = ''
      report() {
        curl -sf -X POST -H "Authorization: Bearer $GATUS_EXTERNAL_TOKEN" \
          --url-query "success=$1" --url-query "error=$2" \
          "http://127.0.0.1:${toString port}/api/v1/endpoints/tailscale_key-expiry/external" >/dev/null
      }

      if ! token=$(curl -sf https://api.tailscale.com/api/v2/oauth/token \
          -d "client_id=$TS_API_CLIENT_ID" -d "client_secret=$TS_API_CLIENT_SECRET" \
          | jq -er .access_token) \
        || ! devices=$(curl -sf -H "Authorization: Bearer $token" \
          https://api.tailscale.com/api/v2/tailnet/-/devices); then
        report false "Tailscale API request failed"
        exit 1
      fi

      horizon=$(( $(date +%s) + 14 * 86400 ))
      problems=$(jq -r --argjson horizon "$horizon" --argjson servers '${builtins.toJSON servers}' '
        [.devices[]
         | (.hostname | ascii_downcase) as $host
         | if .keyExpiryDisabled then empty
           elif ($servers | index($host)) then "\($host): key expiry enabled"
           elif (.expires | sub("\\.[0-9]+"; "") | fromdateiso8601) < $horizon
           then "\($host): key expires \(.expires[:10])"
           else empty end]
        | join("; ")' <<<"$devices")

      if [ -n "$problems" ]; then
        report false "$problems"
      else
        report true ""
      fi
    '';
  };

  systemd.timers.tailscale-key-expiry = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
    };
  };

  # Status page, reachable over the tailnet only.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [config.services.gatus.settings.web.port];
}

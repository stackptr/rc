{
  config,
  lib,
  ...
}: {
  imports = [./grafana-alerts.nix];

  # Kept apart from ./ntfy.nix's root-only slack-bot-token: Grafana reads
  # this one itself, as the grafana user.
  age.secrets.grafana-slack-bot-token = {
    file = ./../secrets/grafana-slack-bot-token.age;
    mode = "440";
    owner = "grafana";
    group = "grafana";
  };

  age.secrets.grafana-client-secret = {
    file = ./../secrets/grafana-client-secret.age;
    mode = "440";
    owner = "grafana";
    group = "grafana";
  };

  age.secrets.grafana-secret-key = {
    file = ./../secrets/grafana-secret-key.age;
    mode = "440";
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        # spore proxies grafana.zx.dev here over the tailnet (tailscale0 is
        # a trusted interface); other interfaces don't open port 3000.
        http_addr = "0.0.0.0";
        http_port = 3000;
        enforce_domain = true;
        enable_gzip = true;
        domain = "grafana.zx.dev";
        root_url = "https://grafana.zx.dev";
      };
      auth = {
        disable_login_form = true;
        oauth_allow_insecure_email_lookup = true;
      };
      "auth.generic_oauth" = {
        enabled = true;
        client_id = "grafana";
        client_secret = "$__file{${config.age.secrets.grafana-client-secret.path}}";
        scopes = "openid email profile";
        auth_url = "https://id.zx.dev/authorize";
        token_url = "https://id.zx.dev/api/oidc/token";
        allow_sign_up = false;
        auto_login = false;
        skip_org_role_sync = true;
      };
      database = {
        type = "postgres";
        host = "127.0.0.1:5432";
        name = "grafana";
        user = "grafana";
        ssl_mode = "disable";
      };
      security = {
        admin_user = "corey@zx.dev";
        admin_email = "corey@zx.dev";
        secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
      };
      unified_alerting = {
        resolve_timeout = "1m";
      };
      # provisionGrafana below points the renderer's browser at http_addr,
      # which is 0.0.0.0 here, and a Host other than grafana.zx.dev fails
      # enforce_domain. Load pages through the public URL instead.
      rendering.callback_url = lib.mkForce "https://grafana.zx.dev/";
    };
    provision = {
      enable = true;
      dashboards.settings.providers = [
        {
          name = "system";
          options.path = ./dashboards;
          disableDeletion = true;
        }
      ];
      alerting.contactPoints.settings.contactPoints = [
        {
          name = "slack";
          receivers = [
            {
              uid = "slack";
              type = "slack";
              settings = {
                token = "$__file{${config.age.secrets.grafana-slack-bot-token.path}}";
                recipient = "#updates";
                username = "Grafana";
                icon_emoji = ":grafana:";
                title = ''{{ if .Alerts.Firing }}[FIRING] {{ .GroupLabels.alertname }}{{ else }}[RESOLVED] {{ .GroupLabels.alertname }}{{ end }}'';
                text = ''                  {{ range .Alerts }}• {{ .Labels.alertname }}: {{ .Annotations.summary }}
                  {{ end }}'';
              };
            }
          ];
        }
      ];
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          # Pinned to the UID Grafana derived from the name, so provisioned
          # alert rules can reference it.
          uid = "PBFA97CFB590B2093";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
          editable = false;
        }
        {
          name = "Loki";
          uid = "P8E80F9AEF21F6940";
          type = "loki";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
          editable = false;
          # Loki has no ruler configured; alert rules are Grafana-managed.
          # Without this, Alerting > Alert rules shows "Cannot load rules
          # for this datasource".
          jsonData.manageAlerts = false;
        }
      ];
    };
  };

  # Headless Chromium for panel and dashboard PNGs (/render, and
  # grafana-mcp's get_panel_image). Listens on localhost:8081 only.
  services.grafana-image-renderer = {
    enable = true;
    provisionGrafana = true;
  };
}

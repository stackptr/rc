{
  config,
  pkgs,
  ...
}: {
  age.secrets.grafana-client-secret = {
    file = ./../secrets/grafana-client-secret.age;
    mode = "440";
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
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
      security = {
        admin_user = "corey@zx.dev";
        admin_email = "corey@zx.dev";
      };
    };
  };
}

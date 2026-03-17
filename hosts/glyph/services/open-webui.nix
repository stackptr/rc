{
  config,
  pkgs,
  ...
}: {
  age.secrets.open-webui-env.file = ./../secrets/open-webui-env.age;

  systemd.services.open-webui.restartTriggers = [config.age.secrets.open-webui-env.file];

  services.open-webui = {
    enable = true;
    package = pkgs.open-webui.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ old.optional-dependencies.postgres;
    });
    port = 8888;
    host = "0.0.0.0";
    environmentFile = config.age.secrets.open-webui-env.path;
    environment = {
      ENABLE_OLLAMA_API = "False";
      ENABLE_SIGNUP = "False";
      ENABLE_PERSISTENT_CONFIG = "False";
      WEBUI_URL = "https://chat.zx.dev";
      WEBUI_SESSION_COOKIE_SECURE = "True";
      CORS_ALLOW_ORIGIN = "https://chat.zx.dev";
      ENABLE_VERSION_UPDATE_CHECK = "False";

      # OIDC via Pocket ID
      ENABLE_OAUTH_SIGNUP = "true";
      OAUTH_PROVIDER_NAME = "Pocket ID";
      OPENID_PROVIDER_URL = "https://id.zx.dev/.well-known/openid-configuration";
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
      OAUTH_SCOPES = "openid email profile groups";
      ENABLE_OAUTH_ROLE_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_CREATION = "true";
      OAUTH_ROLES_CLAIM = "groups";
      OAUTH_ALLOWED_ROLES = "users, admins";
      OAUTH_ADMIN_ROLES = "admins";
      ENABLE_LOGIN_FORM = "false";
      ENABLE_API_KEYS = "True";
      USER_PERMISSIONS_FEATURES_API_KEYS = "True";
      DATABASE_URL = "postgresql:///open-webui?host=/run/postgresql";
    };
  };
}

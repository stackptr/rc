{config, ...}: {
  age.secrets.open-webui-env.file = ./../secrets/open-webui-env.age;

  services.open-webui = {
    enable = true;
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
    };
  };
}

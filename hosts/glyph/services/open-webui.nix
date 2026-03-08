{
  config,
  pkgs,
  ...
}: {
  services.open-webui = {
    enable = true;
    port = 8888;
    host = "0.0.0.0";
    environment = {
      ENABLE_OLLAMA_API = "False";
    };
  };
}

{
  config,
  pkgs,
  ...
}: {
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        enforce_domain = true;
        enable_gzip = true;
        domain = "grafana.zx.dev";
      };
    };
  };
}

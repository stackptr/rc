# Nginx virtual host definitions
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.zx-dev = {
    enable = true;
    domain = "zx.dev";
  };
  services.nginx.virtualHosts = {
    "cjohns.com" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".return = "302 https://zx.dev";
    };
    "rey.foo" = {
      # forceSSL = true;
      # useACMEHost = "rey.foo";
      locations."/".return = "302 https://zx.dev";
    };
    "zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations = {
        "/.well-known/webfinger" = {
          extraConfig = ''
            add_header Access-Control-Allow-Origin '*';
          '';
          return = "301 https://pub.zx.dev$request_uri";
        };
        "/pgp".return = "302 https://keyoxide.org/hkp/413d1a0152bcb08d2e3ddacaf88c08579051ab48";
      };
    };
    "torrents.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      requireAuth = true;
      locations."/".proxyPass = "http://glyph.rove-duck.ts.net:9091";
      locations."~ (/transmission)?/rpc".proxyPass = "http://glyph.rove-duck.ts.net:9091";
    };
    "homebridge.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8581";
    };
    "ha.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8123";
    };
    "files.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      requireAuth = true;
      locations."/".proxyPass = "http://glyph.rove-duck.ts.net:8080";
    };
    "home.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      requireAuth = true;
      locations."/".proxyPass = "http://127.0.0.1:8082";
    };
    "grafana.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      requireAuth = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
    };
  };
}

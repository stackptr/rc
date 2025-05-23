{
  config,
  pkgs,
  agenix,
  ...
}: {
  age.secrets.cloudflare-dns.file = ./../../secrets/cloudflare-dns.age;

  security.acme = {
    acceptTerms = true;
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    defaults.email = "corey@zx.dev";
    certs."zx.dev" = {
      domain = "*.zx.dev";
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns.path;
      extraDomainNames = ["zx.dev"];
    };
  };
  users.users.nginx.extraGroups = ["acme"];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    additionalModules = [pkgs.nginxModules.develkit pkgs.nginxModules.set-misc];
    virtualHosts."rey.foo" = {
      # forceSSL = true;
      # useACMEHost = "rey.foo";
      locations."/".return = "302 https://zx.dev";
    };
    virtualHosts."zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations = {
        "/".proxyPass = "http://127.0.0.1:3001";
        "/.well-known/webfinger" = {
          extraConfig = ''
            add_header Access-Control-Allow-Origin '*';
          '';
          return = "301 https://pub.zx.dev$request_uri";
        };
      };
    };
    virtualHosts."auth.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      useAutheliaProxyConf = true;
      locations."/".proxyPass = "http://127.0.0.1:9091";
      locations."/api/verify".proxyPass = "http://127.0.0.1:9091";
    };
    virtualHosts."torrents.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      enableAutheliaAuth = true;
      locations."/".proxyPass = "http://glyph.rove-duck.ts.net:9091";
      locations."~ (/transmission)?/rpc".proxyPass = "http://glyph.rove-duck.ts.net:9091";
    };
    virtualHosts."homebridge.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8581";
    };
    virtualHosts."ha.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8123";
    };
    virtualHosts."files.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      enableAutheliaAuth = true;
      locations."/".proxyPass = "http://glyph.rove-duck.ts.net:8080";
    };
    virtualHosts."home.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      enableAutheliaAuth = true;
      locations."/".proxyPass = "http://127.0.0.1:8082";
    };
  };
}

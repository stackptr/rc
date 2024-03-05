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
    virtualHosts."portainer.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "https://zeta.rove-duck.ts.net:9443";
    };
    virtualHosts."dsm.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "https://melchior.rove-duck.ts.net:5001";
    };
    virtualHosts."torrents.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      enableAutheliaAuth = true;
      locations."/".proxyPass = "http://melchior.rove-duck.ts.net:9091";
      locations."~ (/transmission)?/rpc".proxyPass = "http://melchior.rove-duck.ts.net:9091";
    };
    virtualHosts."homebridge.zx.dev" = {
      forceSSL = true;
      useACMEHost = "zx.dev";
      locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8581";
    };
  };
}

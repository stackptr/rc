{
  config,
  pkgs,
  ...
}: {
  age.secrets.cloudflare-dns.file = ./secrets/cloudflare-dns.age;
  containers.web = {
    autoStart = true;
    bindMounts = {
      cloudflareDns = {
        mountPoint = config.age.secrets.cloudflare-dns.path;
        hostPath = config.age.secrets.cloudflare-dns.path;
      };
    };
    config = {
      config,
      pkgs,
      ...
    }: {
      security.acme = {
        acceptTerms = true;
        defaults.email = "admin@xor.ooo";
        certs."xor.ooo" = {
          domain = "*.xor.ooo";
          dnsProvider = "cloudflare";
          environmentFile = config.age.secrets.cloudflare-dns.path;
          dnsPropagationCheck = true;
        };
      };
      users.users.nginx.extraGroups = [ "acme" ];
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."xor.ooo" = {
          forceSSL = true;
          useACMEHost = "xor.ooo";
          locations."/corey".proxyPass = "http://zeta.rove-duck.ts.net:3001";
        };
        virtualHosts."portainer" = {
          locations."/".proxyPass = "https://zeta.rove-duck.ts.net:9443";
          listen = [
            {
              addr = "0.0.0.0";
              port = 9443;
            }
          ];
        };
      };
    };
  };
}

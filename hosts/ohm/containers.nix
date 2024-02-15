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
        mountPoint = "/run/cloudflare-dns";
        hostPath = config.age.secrets.cloudflare-dns.path;
      };
    };
    ephemeral = true;
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
          environmentFile = "/run/cloudflare-dns";
          extraDomainNames = ["xor.ooo"];
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
          locations."/".return = "302 /corey";
          locations."/corey".proxyPass = "http://zeta.rove-duck.ts.net:3001";
        };
        virtualHosts."portainer.xor.ooo" = {
          forceSSL = true;
          useACMEHost = "xor.ooo";
          locations."/".proxyPass = "https://zeta.rove-duck.ts.net:9443";
        };
      };
    };
  };
}

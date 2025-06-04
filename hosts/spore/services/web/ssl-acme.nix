# SSL/TLS and ACME certificate configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  age.secrets.cloudflare-dns.file = ../../secrets/cloudflare-dns.age;

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
}

# Core nginx service configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    additionalModules = [pkgs.nginxModules.develkit pkgs.nginxModules.set-misc];
  };
}

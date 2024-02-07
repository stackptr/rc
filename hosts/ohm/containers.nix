{
  config,
  pkgs,
  ...
}: {
  containers.web = {
    autoStart = true;
    config = { config, pkgs, ... }: {
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          virtualHosts."x64.co" = {
            locations."/".proxyPass = "http://zeta.rove-duck.ts.net:3001";
            listen = [
              {
                addr = "0.0.0.0";
                port = 3001;
              }
            ];
          };
        };
        networking.firewall.allowedTCPPorts = [ 80 3001 ];
    };
  };
}
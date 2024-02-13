{
  config,
  pkgs,
  ...
}: {
  containers.web = {
    autoStart = true;
    config = {
      config,
      pkgs,
      ...
    }: {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."xor.ooo" = {
          locations."/corey".proxyPass = "http://zeta.rove-duck.ts.net:3001";
          listen = [
            {
              addr = "0.0.0.0";
              port = 3001;
            }
          ];
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

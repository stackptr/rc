{
  config,
  pkgs,
  ...
}: let
  appHost = "id.zx.dev";
in {
  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://${appHost}";
      TRUST_PROXY = true;
    };
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${appHost} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:1411";
        proxyWebsockets = true;
      };
    };
  };
}

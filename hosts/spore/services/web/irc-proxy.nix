# IRC proxy stream configuration for ZNC
{
  config,
  pkgs,
  lib,
  ...
}: let
  port = 6697;
in {
  services.nginx.streamConfig = let
    inherit (config.security.acme) certs;
    certName = "zx.dev";
  in ''
    upstream znc {
        server zeta.rove-duck.ts.net:5000;
    }

    server {
        listen ${toString port} ssl;

        ssl_certificate ${certs.${certName}.directory}/fullchain.pem;
        ssl_certificate_key ${certs.${certName}.directory}/key.pem;

        # intermediate configuration
        ssl_protocols ${config.services.nginx.sslProtocols};
        ssl_ciphers ${config.services.nginx.sslCiphers};
        ssl_prefer_server_ciphers off;

        # Proxy stream
        proxy_pass znc;
        proxy_ssl on;
        proxy_ssl_certificate ${certs.${certName}.directory}/fullchain.pem;
        proxy_ssl_certificate_key ${certs.${certName}.directory}/key.pem;
        proxy_ssl_protocols ${config.services.nginx.sslProtocols};
        proxy_ssl_ciphers ${config.services.nginx.sslCiphers};
        proxy_ssl_session_reuse on;
    }
  '';

  networking.firewall.allowedTCPPorts = [port];
}

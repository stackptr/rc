{
  config,
  pkgs,
  lib,
  ...
}: let
  vhostOptionsAuth = {config, ...}: {
    options = {
      enableAutheliaAuth = lib.mkEnableOption "Enable authelia auth";
    };
    config = lib.mkIf config.enableAutheliaAuth {
      locations."/authelia".extraConfig = ''
        set $upstream_authelia http://127.0.0.1:9091/api/verify;

        ## Essential Proxy Configuration
        internal;
        proxy_pass $upstream_authelia;

        ## Headers
        ## The headers starting with X-* are required.
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Original-Method $request_method;
        proxy_set_header X-Forwarded-Method $request_method;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Content-Length "";
        proxy_set_header Connection "";

        ## Basic Proxy Configuration
        proxy_pass_request_body off;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; # Timeout if the real server is dead
        proxy_redirect http:// $scheme://;
        proxy_http_version 1.1;
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 4 32k;
        client_body_buffer_size 128k;

        ## Advanced Proxy Configuration
        send_timeout 5m;
        proxy_read_timeout 240;
        proxy_send_timeout 240;
        proxy_connect_timeout 240;
      '';
      locations."/".extraConfig = ''
        ## Send a subrequest to Authelia to verify if the user is authenticated and has permission to access the resource.
        auth_request /authelia;

        ## Set the $target_url variable based on the original request.

        ## Requires nginx http_set_misc module.
        set_escape_uri $target_url $scheme://$http_host$request_uri;

        ## Save the upstream response headers from Authelia to variables.
        auth_request_set $user $upstream_http_remote_user;
        auth_request_set $groups $upstream_http_remote_groups;
        auth_request_set $name $upstream_http_remote_name;
        auth_request_set $email $upstream_http_remote_email;

        ## Inject the response headers from the variables into the request made to the backend.
        proxy_set_header Remote-User $user;
        proxy_set_header Remote-Groups $groups;
        proxy_set_header Remote-Name $name;
        proxy_set_header Remote-Email $email;

        ## If the subreqest returns 200 pass to the backend, if the subrequest returns 401 redirect to the portal.
        error_page 401 =302 https://auth.zx.dev/?rd=$target_url;
      '';
    };
  };

  vhostOptionsProxy = {config, ...}: {
    options = {
      useAutheliaProxyConf = lib.mkEnableOption "Use recommended authelia proxy configuration";
    };
    config = lib.mkIf config.useAutheliaProxyConf {
      locations."/".extraConfig = ''
        ## Headers
        proxy_set_header Host $host;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Connection "";

        ## Basic Proxy Configuration
        client_body_buffer_size 128k;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; ## Timeout if the real server is dead.
        proxy_redirect  http://  $scheme://;
        proxy_http_version 1.1;
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 64 256k;

        ## Trusted Proxies Configuration
        ## Please read the following documentation before configuring this:
        ##     https://www.authelia.com/integration/proxies/nginx/#trusted-proxies
        # set_real_ip_from 10.0.0.0/8;
        # set_real_ip_from 172.16.0.0/12;
        # set_real_ip_from 192.168.0.0/16;
        # set_real_ip_from fc00::/7;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        ## Advanced Proxy Configuration
        send_timeout 5m;
        proxy_read_timeout 360;
        proxy_send_timeout 360;
        proxy_connect_timeout 360;
      '';
    };
  };

  port = 6697;
in {
  # Extend nginx virtual host options for Authelia integration
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule [vhostOptionsAuth vhostOptionsProxy]);
  };

  config = {
    # SSL/TLS and ACME configuration
    age.secrets.cloudflare-dns.file = ../secrets/cloudflare-dns.age;

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

    # Main nginx configuration
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      additionalModules = [pkgs.nginxModules.develkit pkgs.nginxModules.set-misc];

      # HTTP virtual hosts
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

      # IRC proxy stream configuration
      streamConfig = let
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

            # TODO: security.dhparams.enable
            #ssl_dhparam config.security.dhparams.path;

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
    };

    networking.firewall.allowedTCPPorts = [port];
  };
}

# Web services and nginx configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./auth.nix
    ./irc-proxy.nix
    ./srv.nix
  ];

  age.secrets.cloudflare-dns.file = ../../secrets/cloudflare-dns.age;

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    additionalModules = [pkgs.nginxModules.develkit pkgs.nginxModules.set-misc];

    virtualHosts = {
      "cjohns.com" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/".return = "302 https://zx.dev";
        locations."= /resume".return = "302 https://github.com/stackptr/resume/releases/download/latest/resume.pdf";
      };
      "rey.foo" = {
        # forceSSL = true;
        # useACMEHost = "rey.foo";
        locations."/".return = "302 https://zx.dev";
      };
      "zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations = {
          "/.well-known/webfinger" = {
            extraConfig = ''
              add_header Access-Control-Allow-Origin '*';
            '';
            return = "301 https://pub.zx.dev$request_uri";
          };
          "/pgp".return = "302 https://keyoxide.org/hkp/413d1a0152bcb08d2e3ddacaf88c08579051ab48";
        };
      };
      "windmill.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/" = {
          proxyPass = "http://glyph.rove-duck.ts.net:8100";
          proxyWebsockets = true;
        };
      };
      "torrents.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        requireAuth = true;
        locations."/".proxyPass = "http://glyph.rove-duck.ts.net:9091";
        locations."~ (/transmission)?/rpc".proxyPass = "http://glyph.rove-duck.ts.net:9091";
      };
      "homebridge.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/".proxyPass = "http://zeta.rove-duck.ts.net:8581";
      };
      "ha.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/" = {
          proxyPass = "http://zeta.rove-duck.ts.net:8123";
          proxyWebsockets = true;
        };
      };
      "files.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        requireAuth = true;
        locations."/".proxyPass = "http://glyph.rove-duck.ts.net:8080";
      };
      "home.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        requireAuth = true;
        locations."/".proxyPass = "http://127.0.0.1:8082";
      };
      "grafana.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      };
      "chat.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/" = {
          proxyPass = "http://glyph.rove-duck.ts.net:8888";
          proxyWebsockets = true;
        };
      };
      "code.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        requireAuth = true;
        locations."/" = {
          proxyPass = "http://glyph.rove-duck.ts.net:8890";
          proxyWebsockets = true;
        };
      };
      "cache.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/" = {
          proxyPass = "http://glyph.rove-duck.ts.net:8199";
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 300;
            proxy_buffering off;
            proxy_http_version 1.1;
          '';
        };
      };
      "jellyfin.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."/".proxyPass = "http://glyph.rove-duck.ts.net:8096";
      };
      "mcp.zx.dev" = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations = {
          "= /.well-known/oauth-protected-resource" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin '*' always;
              add_header Cache-Control 'public, max-age=3600' always;
              return 200 '${builtins.toJSON {
                resource = "https://mcp.zx.dev";
                authorization_servers = ["https://id.zx.dev"];
                scopes_supported = ["openid" "profile" "email"];
                bearer_methods_supported = ["header"];
              }}';
            '';
          };
          "= /oauth2/auth" = {
            proxyPass = "http://127.0.0.1:4180";
            extraConfig = ''
              proxy_set_header X-Original-URI $request_uri;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header Content-Length "";
              proxy_pass_request_body off;
            '';
          };
          "@mcp_unauthorized" = {
            extraConfig = ''
              default_type application/json;
              add_header WWW-Authenticate 'Bearer resource_metadata="https://mcp.zx.dev/.well-known/oauth-protected-resource"' always;
              return 401 '{"error":"unauthorized","error_description":"Bearer token required"}';
            '';
          };
          "/" = {
            proxyPass = "http://glyph.rove-duck.ts.net:8090";
            extraConfig = ''
              auth_request /oauth2/auth;
              error_page 401 = @mcp_unauthorized;

              # Pass auth info to upstream
              auth_request_set $auth_user $upstream_http_x_auth_request_user;
              auth_request_set $auth_email $upstream_http_x_auth_request_email;
              proxy_set_header X-Auth-User $auth_user;
              proxy_set_header X-Auth-Email $auth_email;
            '';
          };
        };
      };
    };
  };

  services.zx-dev = {
    enable = true;
    domain = "zx.dev";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "corey@zx.dev";
    certs."zx.dev" = {
      domain = "*.zx.dev";
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns.path;
      extraDomainNames = ["zx.dev" "cjohns.com"];
    };
  };
  users.users.nginx.extraGroups = ["acme"];
}

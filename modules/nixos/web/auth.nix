{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption;

  cfg = config.rc.web.auth;

  # TODO: Source from web-servers/nginx/vhost-options.nix
  useACMEHost = mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = ''
      A host of an existing Let's Encrypt certificate to use.
    '';
  };
in {
  options = {
    rc.web.auth = {
      enable = lib.mkEnableOption "Web authentication stack";

      issuer = {
        inherit useACMEHost;

        host = lib.mkOption {
          type = lib.types.str;
          description = ''
            The OAuth issuer host.
          '';
          example = "id.example.org";
        };

        encryptionKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Key used to encrypt OAuth issuer data, including the private keys.
          '';
          example = "/run/keys/oauth-issuer-encryption-key";
        };
      };

      authProxy = {
        inherit useACMEHost;

        host = lib.mkOption {
          type = lib.types.str;
          description = ''
            The host where OAuth proxy is accessed for shared SSO.
          '';
          example = "auth.example.org";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          description = ''
            The domain in which proxy redirection occurs and cookies are scoped.
          '';
          example = ".example.org";
        };

        clientID = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = ''
            The client ID for the OAuth proxy.
          '';
          example = "123456.apps.googleusercontent.com";
        };

        keyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            oauth2-proxy allows passing sensitive configuration via environment variables.
            Make a file that contains lines like
            OAUTH2_PROXY_CLIENT_SECRET=asdfasdfasdf.apps.googleuserscontent.com
            and specify the path here.
          '';
          example = "/run/keys/oauth2-proxy";
        };
      };
    };

    services.nginx.virtualHosts = let
      requireAuthOption = {config, ...}: {
        options = {
          requireAuth = lib.mkEnableOption "Require authentication to access host.";
        };
        config = lib.mkIf config.requireAuth {
          locations."= /oauth2/auth" = {
            proxyPass = "http://127.0.0.1:4180";
            extraConfig = ''
              proxy_set_header X-Original-URI $request_uri;
              proxy_set_header X-Real-IP      $remote_addr;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header Content-Length "";
              proxy_pass_request_body off;
            '';
          };
          locations."@oauth2_redirect" = {
            extraConfig = ''
              return 302 https://${cfg.authProxy.host}/oauth2/start?rd=$scheme://$http_host$request_uri;
            '';
          };
          locations."/".extraConfig = ''
            auth_request /oauth2/auth;
            error_page 401 = @oauth2_redirect;
          '';
        };
      };
    in
      lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule [requireAuthOption]);
      };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      services.pocket-id = {
        enable = true;
        settings = {
          APP_URL = "https://${cfg.issuer.host}";
          TRUST_PROXY = true;
          DB_CONNECTION_STRING = "host=/run/postgresql user=pocketid dbname=pocketid";
          KEYS_STORAGE = "database";
          ENCRYPTION_KEY_FILE = cfg.issuer.encryptionKeyFile;
        };
      };

      services.postgresql = {
        ensureDatabases = ["pocketid"];
        ensureUsers = [
          {
            name = "pocketid";
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services.pocket-id = {
        wants = ["network-online.target"];
        after = ["postgresql.service" "network-online.target"];
        requires = ["postgresql.service"];
      };

      services.oauth2-proxy = {
        enable = true;
        provider = "oidc";
        oidcIssuerUrl = "https://${cfg.issuer.host}";
        inherit (cfg.authProxy) keyFile;
        reverseProxy = true;
        setXauthrequest = true;
        inherit (cfg.authProxy) clientID;
        redirectURL = "https://${cfg.authProxy.host}/oauth2/callback";
        nginx.domain = cfg.authProxy.host;
        cookie.domain = cfg.authProxy.domain;
        email.domains = ["*"];
        extraConfig = {
          whitelist-domain = cfg.authProxy.domain;
          insecure-oidc-allow-unverified-email = true;
        };
      };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts.${cfg.issuer.host} = {
          forceSSL = true;
          inherit (cfg.issuer) useACMEHost;
          locations."/" = {
            proxyPass = "http://127.0.0.1:1411";
            proxyWebsockets = true;
          };
        };

        virtualHosts.${cfg.authProxy.host} = {
          forceSSL = true;
          inherit (cfg.authProxy) useACMEHost;
          locations."/oauth2/" = {
            proxyPass = "http://127.0.0.1:4180";
            extraConfig = ''
              proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
            '';
          };
          locations."/oauth2/auth" = {
            proxyPass = "http://127.0.0.1:4180";
            extraConfig = ''
              proxy_set_header Content-Length "";
              proxy_pass_request_body off;
            '';
          };
          locations."/" = {
            extraConfig = ''
              default_type text/html;
              add_header Content-Type "text/html; charset=utf-8";
              return 200 '<!doctype html><title>Auth</title><p>oauth2-proxy at ${cfg.authProxy.host}</p>';
            '';
          };
        };
      };
    })
    (let
      vhosts = config.services.nginx.virtualHosts;
      vhostsRequiringAuth = mapNames (lib.filter (set: set.value.requireAuth) (lib.attrsToList vhosts));
      mapNames = e: toString (lib.map (set: set.name) e);
    in
      mkIf (!cfg.enable && vhostsRequiringAuth != "") {
        warnings = [
          "The following nginx hosts have requireAuth, but config.rc.web.auth is not enabled: ${vhostsRequiringAuth}"
        ];
      })
  ];
}

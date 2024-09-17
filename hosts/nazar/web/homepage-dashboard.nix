{
  config,
  pkgs,
  ...
}: {
  age.secrets.homepage-env.file = ./../secrets/homepage-env.age;
  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.age.secrets.homepage-env.path;
    settings = {
      color = "sky";
      target = "_self";
      title = "home.zx.dev";
    };
    bookmarks = [];
    widgets = [
      {
        search = {
          provider = "custom";
          url = "https://kagi.com/search?q=";
          target = "_blank";
          suggestionUrl = "https://kagi.com/api/autosuggest?q=";
          showSearchSuggestions = true;
        };
      }
      {
        datetime = {
          text_size = "xl";
          format.timeStyle = "short";
        };
      }
      {
        openweathermap = {
          units = "imperial";
          provider = "openweathermap";
          cache = 5;
          apiKey = "{{HOMEPAGE_VAR_OPENWEATHERMAP_APIKEY}}";
        };
      }
    ];
    services = [
      {
        Network = [
          {
            "Tailscale" = {
              description = "Secured infrastructure";
              href = "https://login.tailscale.com/admin/machines";
              icon = "tailscale";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICEID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_KEY}}";
              };
            };
          }
          {
            "NextDNS" = {
              href = "https://my.nextdns.io";
              icon = "nextdns";
              widget = {
                type = "nextdns";
                profile = "{{HOMEPAGE_VAR_NEXTDNS_PROFILE_ID}}";
                key = "{{HOMEPAGE_VAR_NEXTDNS_KEY}}";
              };
            };
          }
        ];
      }
      {
        Services = [
          {
            "Transmission" = {
              description = "Torrent client";
              href = "https://torrents.zx.dev";
              icon = "transmission";
              widget = {
                type = "transmission";
                url = "http://glyph.rove-duck.ts.net:9091";
                rpcUrl = "/transmission/";
              };
            };
          }
          {
            "Plex" = {
              description = "TV & movie streaming";
              href = "https://app.plex.tv";
              icon = "plex";
              widget = {
                type = "plex";
                url = "https://glyph.rove-duck.ts.net:32400";
                key = "{{HOMEPAGE_VAR_PLEX_KEY}}";
              };
            };
          }
        ];
      }
    ];
  };
}

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
        datetime = {
          text_size = "xl";
          format.timeStyle = "short";
        };
      }
      {
        search = {
          provider = "custom";
          url = "https://kagi.com/search?q=";
          target = "_blank";
          suggestionUrl = "https://kagi.com/api/autosuggest?q=";
          showSearchSuggestions = true;
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
        ];
      }
      {
        Services = [
          {
            "Transmission" = {
              description = "Torrent client with web UI.";
              href = "https://torrents.zx.dev";
              icon = "transmission";
              widget = {
                type = "transmission";
                url = "http://glyph.rove-duck.ts.net:9091";
                rpcUrl = "/transmission/";
              };
            };
          }
        ];
      }
    ];
  };
}

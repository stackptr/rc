{
  config,
  pkgs,
  ...
}: {
  age.secrets.jwt-secret = {
    file = ./../secrets/jwt-secret.age;
    mode = "440";
    owner = "authelia-main";
    group = "authelia-main";
  };
  services.homepage-dashboard = {
    enable = true;
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
        Services = [
          {
            "Transmission" = {
              description = "Torrent client with web UI.";
              href = "http://glyph.rove-duck.ts.net:9091";
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

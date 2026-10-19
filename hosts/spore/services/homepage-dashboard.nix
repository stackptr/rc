{
  config,
  pkgs,
  ...
}: let
  # Homepage's widgets query Prometheus on glyph over the tailnet (tailscale0
  # is trusted there), which needs no credentials, unlike Grafana's API.
  prometheus = "http://glyph.note-iwato.ts.net:9099";

  # Last switch per NixOS host, from deploy-marker's textfile metric.
  lastDeploy = host: {
    label = host;
    query = ''max(nixos_deploy_timestamp_seconds{host="${host}"})'';
    format = {
      type = "relativeDate";
      scale = 1000;
      options.numeric = "auto";
    };
  };
in {
  age.secrets.homepage-env.file = ./../secrets/homepage-env.age;
  services.homepage-dashboard = {
    enable = true;
    environmentFiles = [config.age.secrets.homepage-env.path];
    allowedHosts = "localhost:8082,127.0.0.1:8082,dash.zx.dev";
    settings = {
      color = "sky";
      target = "_self";
      title = "dash.zx.dev";
    };
    bookmarks = [];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
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
          {
            "Network Usage" = {
              widget = {
                type = "glances";
                url = "http://localhost:${builtins.toString config.services.glances.port}";
                version = 4;
                metric = "network:eth0";
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
                url = "http://glyph.note-iwato.ts.net:9091";
                rpcUrl = "/transmission/";
              };
            };
          }
          {
            "Open WebUI" = {
              description = "AI chat interface";
              href = "https://chat.zx.dev";
              icon = "open-webui";
            };
          }
          {
            "oMLX" = {
              description = "Local LLMs on Stroma";
              href = "https://monitoring.zx.dev/d/apple-silicon";
              icon = "mdi-chip";
              widget = {
                type = "prometheusmetric";
                url = prometheus;
                refreshInterval = 30000;
                metrics = [
                  {
                    label = "Loaded";
                    query = "max(omlx_models_loaded)";
                  }
                  {
                    label = "Requests";
                    query = "max(omlx_requests_active)";
                  }
                  {
                    # Averaged since oMLX started.
                    label = "Gen speed";
                    query = "max(omlx_avg_generation_tokens_per_second)";
                    format = {
                      type = "number";
                      suffix = " tok/s";
                      options.maximumFractionDigits = 1;
                    };
                  }
                  {
                    label = "Power";
                    query = ''max(mactop_power_watts{component="total"})'';
                    format = {
                      type = "number";
                      suffix = " W";
                      options.maximumFractionDigits = 0;
                    };
                  }
                ];
              };
            };
          }
          {
            "oMLX Models" = {
              description = "Available for inference";
              href = "https://models.zx.dev";
              icon = "mdi-chip";
              widget = {
                type = "customapi";
                url = "http://stroma.note-iwato.ts.net:8000/v1/models";
                refreshInterval = 60000;
                # oMLX requires a key on any non-loopback bind
                # (hosts/Stroma/omlx.nix). HOMEPAGE_VAR_OMLX_KEY is an oMLX sub-key in homepage-env.age.
                headers.Authorization = "Bearer {{HOMEPAGE_VAR_OMLX_KEY}}";
                display = "dynamic-list";
                mappings = {
                  items = "data";
                  name = "id";
                  label = "id";
                  limit = 8;
                };
              };
            };
          }
          {
            "Jellyfin" = {
              description = "TV & movie streaming";
              href = "https://media.zx.dev";
              icon = "jellyfin";
              widget = {
                type = "jellyfin";
                url = "http://glyph.note-iwato.ts.net:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                version = 1;
                enableBlocks = true;
                enableNowPlaying = true;
                enableUser = true;
                enableMediaControl = true;
                showEpisodeNumber = true;
                expandOneStreamToTwoRows = true;
              };
            };
          }
          {
            "FreshRSS" = {
              description = "RSS reader";
              href = "https://rss.zx.dev";
              icon = "freshrss";
            };
          }
        ];
      }
      {
        Monitoring = [
          {
            "Grafana" = {
              description = "Alerts & dashboards";
              href = "https://monitoring.zx.dev";
              icon = "grafana";
              widget = {
                type = "prometheusmetric";
                url = prometheus;
                refreshInterval = 60000;
                metrics = [
                  {
                    label = "Firing";
                    query = ''sum(grafana_alerting_alerts{state="alerting"}) or vector(0)'';
                  }
                  {
                    label = "Targets down";
                    query = "count(up == 0) or vector(0)";
                  }
                  {
                    label = "Failed units";
                    query = ''sum(node_systemd_unit_state{state="failed"})'';
                  }
                  {
                    label = "ZFS used";
                    query = "max(zfs_pool_allocated_bytes / zfs_pool_size_bytes) * 100";
                    format = {
                      type = "percent";
                      options.maximumFractionDigits = 0;
                    };
                  }
                ];
              };
            };
          }
          {
            # Runs on zeta, so it still reports when glyph (and with it
            # Prometheus and Grafana) is down.
            "Gatus" = {
              description = "Out-of-band watchdog";
              href = "https://status.zx.dev";
              icon = "gatus";
              widget = {
                type = "gatus";
                url = "http://zeta.note-iwato.ts.net:8080";
              };
            };
          }
          {
            "Deploys" = {
              description = "Last switch per host";
              href = "https://github.com/stackptr/rc/actions/workflows/deploy.yml";
              icon = "mdi-rocket-launch";
              widget = {
                type = "prometheusmetric";
                url = prometheus;
                refreshInterval = 300000;
                metrics = map lastDeploy ["glyph" "spore" "zeta"];
              };
            };
          }
        ];
      }
    ];
  };
}

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

  percent = label: query: {
    inherit label query;
    format = {
      type = "percent";
      options.maximumFractionDigits = 0;
    };
  };

  # CPU, memory, disk and boot time for one host, with the queries from the
  # Node and Apple Silicon dashboards.
  hostCard = {
    name,
    description,
    icon,
    cpu,
    memory,
    disk,
  }: {
    ${name} = {
      inherit description icon;
      href = "https://monitoring.zx.dev/d/${
        if name == "stroma"
        then "apple-silicon"
        else "node-overview"
      }?var-instance=${name}";
      widget = {
        type = "prometheusmetric";
        url = prometheus;
        refreshInterval = 30000;
        metrics = [
          (percent "CPU" cpu)
          (percent "Memory" memory)
          (percent "Disk" disk)
          {
            label = "Booted";
            query = ''max(node_boot_time_seconds{host="${name}"})'';
            format = {
              type = "relativeDate";
              scale = 1000;
              options.numeric = "auto";
            };
          }
        ];
      };
    };
  };

  linuxHost = name: description: icon:
    hostCard {
      inherit name description icon;
      cpu = ''100 * (1 - avg(rate(node_cpu_seconds_total{host="${name}", mode="idle"}[5m])))'';
      memory = ''100 * (1 - max(node_memory_MemAvailable_bytes{host="${name}"}) / max(node_memory_MemTotal_bytes{host="${name}"}))'';
      disk = ''100 * (1 - max(node_filesystem_avail_bytes{host="${name}", mountpoint="/"}) / max(node_filesystem_size_bytes{host="${name}", mountpoint="/"}))'';
    };
in {
  age.secrets.homepage-env.file = ./../secrets/homepage-env.age;
  # systemd reads environmentFiles only at start, and the decrypted path never
  # changes, so a new secret otherwise waits for the next restart.
  systemd.services.homepage-dashboard.restartTriggers = [config.age.secrets.homepage-env.file];
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
    # Per-host resources are in the Hosts group: the resources widget only
    # sees spore, where Homepage runs.
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
              widget = {
                type = "prometheusmetric";
                url = prometheus;
                refreshInterval = 60000;
                # Pushed over OTLP every 60s (hosts/glyph/services/open-webui.nix).
                metrics = [
                  {
                    label = "Active";
                    query = "max(webui_users_active)";
                  }
                  {
                    label = "Today";
                    query = "max(webui_users_active_today)";
                  }
                  {
                    label = "Users";
                    query = "max(webui_users_total)";
                  }
                ];
              };
            };
          }
          {
            "OpenCode" = {
              description = "Coding agent on glyph";
              href = "https://code.zx.dev";
              icon = "opencode";
            };
          }
          {
            "File Browser" = {
              description = "Files on glyph";
              href = "https://files.zx.dev";
              icon = "filebrowser";
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
                  # Context window in K tokens (max_model_len / 1024).
                  label = "max_model_len";
                  format = "number";
                  scale = "1/1024";
                  suffix = "K ctx";
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
            "Navidrome" = {
              description = "Music streaming";
              href = "https://music.zx.dev";
              icon = "navidrome";
              widget = {
                type = "navidrome";
                url = "http://glyph.note-iwato.ts.net:4533";
                # Subsonic token auth: TOKEN is md5(password + SALT)
                user = "{{HOMEPAGE_VAR_NAVIDROME_USER}}";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
              };
            };
          }
          {
            "AudioMuse-AI" = {
              description = "Sonic analysis & playlists";
              href = "https://mix.zx.dev";
              icon = "audiomuse-ai.png";
              widget = {
                type = "prometheusmetric";
                url = prometheus;
                refreshInterval = 300000;
                metrics = [
                  {
                    # From a timer on glyph (hosts/glyph/services/audiomuse.nix)
                    label = "Analysed";
                    query = "max(audiomuse_tracks_analysed)";
                  }
                  {
                    label = "Library";
                    query = ''max(db_model_totals{model="media"})'';
                  }
                  {
                    label = "Coverage";
                    query = ''100 * max(audiomuse_tracks_analysed) / max(db_model_totals{model="media"})'';
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
            "FreshRSS" = {
              description = "RSS reader";
              href = "https://rss.zx.dev";
              icon = "freshrss";
              widget = {
                type = "freshrss";
                url = "http://glyph.note-iwato.ts.net:8084";
                # The Google Reader API password from FreshRSS's profile
                # settings, not the login (which is Pocket ID).
                username = "{{HOMEPAGE_VAR_FRESHRSS_USER}}";
                password = "{{HOMEPAGE_VAR_FRESHRSS_PASSWORD}}";
              };
            };
          }
        ];
      }
      {
        Home = [
          {
            "Home Assistant" = {
              description = "Home automation";
              href = "https://home.zx.dev";
              icon = "home-assistant";
              widget = {
                type = "homeassistant";
                # Directly, not through spore, which HA must trust as a proxy.
                url = "http://zeta.note-iwato.ts.net:8123";
                key = "{{HOMEPAGE_VAR_HOMEASSISTANT_KEY}}";
              };
            };
          }
          {
            "Homebridge" = {
              description = "HomeKit bridge";
              href = "https://homekit.zx.dev";
              icon = "homebridge";
              widget = {
                type = "homebridge";
                url = "http://zeta.note-iwato.ts.net:8581";
                username = "{{HOMEPAGE_VAR_HOMEBRIDGE_USER}}";
                password = "{{HOMEPAGE_VAR_HOMEBRIDGE_PASSWORD}}";
              };
            };
          }
        ];
      }
      {
        Hosts = [
          (linuxHost "glyph" "Home server & NAS" "nixos")
          (linuxHost "spore" "VPS" "nixos")
          (linuxHost "zeta" "Raspberry Pi 4" "raspberry-pi")
          (hostCard {
            name = "stroma";
            description = "Mac Studio";
            icon = "mdi-apple";
            cpu = "max(mactop_cpu_usage_percent)";
            memory = ''100 * max(mactop_memory_gb{type="used"}) / max(mactop_memory_gb{type="total"})'';
            # The sealed system volume is a snapshot; data lives here.
            disk = ''100 * (1 - max(node_filesystem_avail_bytes{host="stroma", mountpoint="/System/Volumes/Data"}) / max(node_filesystem_size_bytes{host="stroma", mountpoint="/System/Volumes/Data"}))'';
          })
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

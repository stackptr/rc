# Exporters scraped by Prometheus on glyph over the tailnet (jobs "node",
# "mactop", "omlx" and "alloy", instance "stroma"), and Alloy shipping oMLX's
# log to Loki. The exporters listen on all interfaces; none has a flag to
# bind only the tailnet address.
{
  config,
  pkgs,
  ...
}: let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  # Matches basePath in ./omlx.nix (and the menubar app's default).
  omlxBase = "${home}/.omlx";

  # oMLX has no Prometheus endpoint; json_exporter turns its /api/status
  # JSON into metrics. Prometheus passes the target URL on each scrape (see
  # the "omlx" job on glyph). Counters reset when oMLX restarts.
  jsonExporterConfig = (pkgs.formats.yaml {}).generate "json-exporter.yml" {
    modules.omlx.metrics = let
      gauge = name: field: help: {
        inherit name help;
        path = "{.${field}}";
      };
      counter = name: field: help: gauge name field help // {valuetype = "counter";};
    in [
      {
        name = "omlx";
        type = "object";
        path = "{@}";
        help = "1 while /api/status answers";
        labels = {
          version = "{.version}";
          default_model = "{.default_model}";
        };
        values.info = 1;
      }
      {
        name = "omlx_loaded_model";
        type = "object";
        path = "{.loaded_models[*]}";
        help = "1 per model loaded in memory";
        labels.model = "{@}";
        values.info = 1;
      }
      (gauge "omlx_models_discovered" "models_discovered" "Models found in the model directories")
      (gauge "omlx_models_loaded" "models_loaded" "Models loaded in memory")
      (gauge "omlx_models_loading" "models_loading" "Models currently loading")
      (gauge "omlx_requests_active" "active_requests" "Requests being processed")
      (gauge "omlx_requests_waiting" "waiting_requests" "Requests queued behind the active ones")
      (counter "omlx_requests_total" "total_requests" "Requests served since oMLX started")
      (counter "omlx_prompt_tokens_total" "total_prompt_tokens" "Prompt tokens processed")
      (counter "omlx_completion_tokens_total" "total_completion_tokens" "Tokens generated")
      (counter "omlx_cached_tokens_total" "total_cached_tokens" "Prompt tokens served from the prefix cache")
      (gauge "omlx_cache_efficiency_percent" "cache_efficiency" "Cached share of prompt tokens since start")
      (gauge "omlx_avg_prefill_tokens_per_second" "avg_prefill_tps" "Mean prefill speed since start")
      (gauge "omlx_avg_generation_tokens_per_second" "avg_generation_tps" "Mean generation speed since start")
      (gauge "omlx_model_memory_used_bytes" "model_memory_used" "Memory held by loaded models")
      # null (so absent) unless a memory ceiling is set
      (gauge "omlx_model_memory_limit_bytes" "model_memory_max" "Memory ceiling for loaded models")
      (gauge "omlx_uptime_seconds" "uptime_seconds" "Seconds since oMLX started")
    ];
  };

  alloyConfig = pkgs.writeText "config.alloy" ''
    local.file_match "omlx" {
      path_targets = [{"__path__" = "${omlxBase}/logs/server.log", "app" = "omlx"}]
    }

    loki.source.file "omlx" {
      targets    = local.file_match.omlx.targets
      forward_to = [loki.process.omlx.receiver]
    }

    loki.process "omlx" {
      // Python tracebacks continue a record on lines without a timestamp.
      stage.multiline {
        firstline     = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:"
        max_wait_time = "3s"
      }

      // "%(asctime)s - %(name)s - %(levelname)s - [%(request_id)s] - %(message)s"
      stage.regex {
        expression = "^\\S+ \\S+ - \\S+ - (?P<level>[A-Z]+) - "
      }

      // The journald priority numbers, so {priority=~"[0-3]"} finds oMLX
      // errors too.
      stage.template {
        source   = "priority"
        template = "{{ if eq .level \"CRITICAL\" }}2{{ else if eq .level \"ERROR\" }}3{{ else if eq .level \"WARNING\" }}4{{ else if eq .level \"DEBUG\" }}7{{ else }}6{{ end }}"
      }

      stage.labels {
        values = {priority = ""}
      }

      stage.label_drop {
        values = ["filename"]
      }

      forward_to = [loki.write.glyph.receiver]
    }

    loki.write "glyph" {
      endpoint {
        url = "http://glyph.note-iwato.ts.net:3100/loki/api/v1/push"
      }
      external_labels = {host = "stroma"}
    }
  '';
in {
  # Filesystems, load, uptime: the host-level series the shared alert rules
  # and dashboards already use.
  services.prometheus.exporters.node.enable = true;

  # Apple Silicon metrics node_exporter can't read: CPU by core type, GPU
  # usage and frequency, power per component (CPU, GPU, ANE, DRAM), DRAM
  # bandwidth, SoC/GPU temperatures, thermal state and fans. Uses IOReport
  # and SMC, so no root needed.
  launchd.daemons.mactop.serviceConfig = {
    ProgramArguments = [
      "${pkgs.mactop}/bin/mactop"
      "--headless"
      "--count"
      "0"
      # Sample every 10s; Prometheus scrapes every 60s.
      "--interval"
      "10000"
      "--prometheus"
      "9101"
    ];
    UserName = config.system.primaryUser;
    RunAtLoad = true;
    KeepAlive = true;
    # Headless mode also prints every sample as JSON on stdout.
    StandardOutPath = "/dev/null";
    StandardErrorPath = "/tmp/mactop.log";
  };

  # oMLX's /api/status as metrics. It needs no API key while oMLX listens
  # only on loopback (./omlx.nix).
  launchd.daemons.json-exporter.serviceConfig = {
    ProgramArguments = [
      "${pkgs.prometheus-json-exporter}/bin/json_exporter"
      "--config.file=${jsonExporterConfig}"
      "--web.listen-address=:7979"
    ];
    UserName = user;
    RunAtLoad = true;
    KeepAlive = true;
    StandardOutPath = "/tmp/json-exporter.log";
    StandardErrorPath = "/tmp/json-exporter.log";
  };

  # Ships oMLX's log (per-request tokens, tok/s, TTFT, errors) to Loki as
  # {host="stroma", app="omlx"}. Runs as the user, who owns the log.
  launchd.daemons.alloy.serviceConfig = {
    ProgramArguments = [
      "${pkgs.grafana-alloy}/bin/alloy"
      "run"
      # Prometheus on glyph scrapes Alloy's own metrics (job "alloy").
      "--server.http.listen-addr=0.0.0.0:12345"
      "--storage.path=${home}/Library/Application Support/Alloy"
      "${alloyConfig}"
    ];
    UserName = user;
    RunAtLoad = true;
    KeepAlive = true;
    StandardOutPath = "/tmp/alloy.log";
    StandardErrorPath = "/tmp/alloy.log";
  };
}

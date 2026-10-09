_: {
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };

      schema_config.configs = [
        {
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      storage_config.filesystem.directory = "/var/lib/loki/chunks";

      # Backs /loki/api/v1/patterns (grafana-mcp's query_loki_patterns and
      # Logs Drilldown). Patterns are held in memory, so they cover recent
      # logs only and reset when Loki restarts. Uses the common in-memory ring.
      pattern_ingester.enabled = true;

      limits_config = {
        retention_period = "30d";
        ingestion_burst_size_mb = 16;
        ingestion_rate_mb = 8;
        # OTLP pushes (Claude Code events): index the host resource attribute
        # so {host="..."} works as it does for journald streams. Other
        # attributes land in structured metadata.
        otlp_config.resource_attributes.attributes_config = [
          {
            action = "index_label";
            attributes = ["host"];
          }
        ];
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        delete_request_store = "filesystem";
      };
    };
  };
}

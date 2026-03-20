{_}: {
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

      limits_config = {
        retention_period = "30d";
        ingestion_burst_size_mb = 16;
        ingestion_rate_mb = 8;
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

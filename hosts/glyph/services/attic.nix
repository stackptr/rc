{config, ...}: {
  age.secrets.attic-credentials.file = ./../secrets/attic-credentials.age;

  services.atticd = {
    enable = true;
    environmentFile = config.age.secrets.attic-credentials.path;

    settings = {
      listen = "[::]:8199";

      database.url = "postgresql:///atticd?host=/run/postgresql";

      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      compression = {
        type = "zstd";
      };

      chunking = {
        nar-size-threshold = 65536;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };

      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "30 days";
      };
    };
  };
}

{config, ...}: {
  age.secrets.attic-credentials.file = ./../secrets/attic-credentials.age;

  # Read the cache directly. cache.zx.dev goes out to spore and back over
  # the tailnet, so builds here stalled on 504s while the tailnet was down.
  nix.settings.extra-substituters = ["http://127.0.0.1:8199/main"];

  services.atticd = {
    enable = true;
    environmentFile = config.age.secrets.attic-credentials.path;

    settings = {
      listen = "[::]:8199";

      database.url = "postgresql:///atticd?host=/run/postgresql&user=atticd";

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

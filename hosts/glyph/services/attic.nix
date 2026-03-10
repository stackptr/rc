{config, ...}: {
  age.secrets.attic-credentials = {
    file = ./../secrets/attic-credentials.age;
    mode = "440";
    owner = "atticd";
    group = "atticd";
  };

  services.atticd = {
    enable = true;
    environmentFile = config.age.secrets.attic-credentials.path;

    settings = {
      listen = "[::]:8199";

      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";

      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
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

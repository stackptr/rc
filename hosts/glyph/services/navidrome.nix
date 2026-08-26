{config, ...}: {
  age.secrets.navidrome-env = {
    file = ./../secrets/navidrome-env.age;
    mode = "440";
    owner = config.services.navidrome.user;
    group = config.services.navidrome.group;
  };

  services.navidrome = {
    enable = true;
    openFirewall = true;
    group = "media";
    environmentFile = config.age.secrets.navidrome-env.path;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/mnt/media/Music";
      Scanner.Schedule = "@every 1h";
      RecentlyAddedByModTime = true;
      Prometheus.Enabled = true;
    };
  };
}

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
    # From pkgsCross.wasi32.navidromePlugins; lyrics-plugin is nd-lyrics
    withPlugins = p: [p.apple-music p.audiomuseai p.lyrics-plugin];
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/mnt/media/Music";
      Scanner.Schedule = "@every 1h";
      RecentlyAddedByModTime = true;
      Prometheus.Enabled = true;
      Agents = "audiomuseai,apple-music,lastfm,deezer";
      LyricsPriority = ".ttml,.yaml,.yml,.elrc,.lrc,.srt,.txt,embedded,nd-lyrics";
    };
  };
}

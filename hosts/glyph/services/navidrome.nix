{
  config,
  pkgs,
  ...
}: let
  nd-lyrics = pkgs.stdenvNoCC.mkDerivation {
    pname = "nd-lyrics";
    version = "7.2.0";
    src = pkgs.fetchurl {
      url = "https://github.com/J0R6IT0/navidrome-lyrics-plugin/releases/download/v7.2.0/nd-lyrics.ndp";
      sha256 = "03slqy31d42n2mdnix8z13lqyj3gmygmrwxrrjmb4bic9rdnw6d9";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share
      cp $src $out/share/nd-lyrics.ndp
    '';
    passthru.isNavidromePlugin = true;
  };
in {
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
    plugins = [
      pkgs.navidromePlugins.apple-music
      pkgs.navidromePlugins.audiomuseai
      nd-lyrics
    ];
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/mnt/media/Music";
      Scanner.Schedule = "@every 1h";
      RecentlyAddedByModTime = true;
      Prometheus.Enabled = true;
      Agents = "apple-music,lastfm,deezer,audiomuseai";
      LyricsPriority = ".ttml,.yaml,.yml,.elrc,.lrc,.srt,.txt,embedded,nd-lyrics";
    };
  };
}

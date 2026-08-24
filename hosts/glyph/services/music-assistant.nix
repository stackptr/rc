_: {
  services.music-assistant = {
    enable = true;
    openFirewall = true;
    providers = [
      "opensubsonic" # Navidrome integration
      "airplay"
      "musicbrainz"
      "coverartarchive"
    ];
  };
}

{
  services.feishin = {
    enable = true;
    domain = "music.zx.dev";
    settings = {
      ANALYTICS_DISABLED = "true";
      SERVER_NAME = "glyph";
      SERVER_TYPE = "navidrome";
      SERVER_URL = "https://music.zx.dev";
      SERVER_LOCK = "true";
    };
    nginx = {
      enable = true;
      virtualHost = {
        forceSSL = true;
        useACMEHost = "zx.dev";
        locations."~ ^/(app|auth|api|rest|share|backgrounds|ping)(/|$)".proxyPass = "http://glyph.note-iwato.ts.net:4533";
      };
    };
  };
}

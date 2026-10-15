{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.goodlinks;

  # GoodLinks' built-in API server (Settings → API). It listens on
  # localhost only, and only while the app is running.
  appPort = 9428;
in {
  options.programs.goodlinks = {
    enable = mkEnableOption "GoodLinks";

    api.enable = mkEnableOption "GoodLinks' built-in API server";

    keepRunning = mkEnableOption "keeping GoodLinks running, so its API stays up";

    api.forward = {
      enable = mkEnableOption "forwarding the GoodLinks API to the tailnet";

      address = mkOption {
        type = types.str;
        example = "100.64.0.1";
        description = ''
          Tailscale IPv4 address to listen on. Never `0.0.0.0`: the API token
          gives full access to the library.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 9429;
        description = ''
          Port to listen on. Differs from the app's ${toString appPort} so it
          can't collide if the app ever binds all interfaces.
        '';
      };
    };
  };

  # The App Store install lives in modules/darwin/rc.nix (masApps), since
  # other hosts have GoodLinks too.
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.api.enable {
      system.defaults.CustomUserPreferences."com.ngocluu.goodlinks" = {
        apiEnabled = true;
        # App Nap throttles a hidden app, and the server with it.
        NSAppSleepDisabled = true;
      };
    })

    # A user agent: opening an app needs a login session. Relaunches the app
    # after a quit or crash, and starts it at login.
    (mkIf cfg.keepRunning {
      launchd.user.agents.goodlinks.serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "pgrep -q GoodLinks || open -g -j -a GoodLinks"
        ];
        RunAtLoad = true;
        StartInterval = 300;
      };
    })

    # KeepAlive retries until Tailscale has brought the address up.
    (mkIf cfg.api.forward.enable {
      launchd.user.agents.goodlinks-forward.serviceConfig = {
        ProgramArguments = [
          "${pkgs.socat}/bin/socat"
          "TCP-LISTEN:${toString cfg.api.forward.port},bind=${cfg.api.forward.address},fork,reuseaddr"
          "TCP:127.0.0.1:${toString appPort}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/goodlinks-forward.log";
        StandardErrorPath = "/tmp/goodlinks-forward.log";
      };
    })
  ]);
}

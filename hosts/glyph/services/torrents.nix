{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  age.secrets.pushover-user-token = {
    file = ./../secrets/pushover-user-token.age;
    mode = "550";
    owner = config.services.transmission.user;
    inherit (config.services.transmission) group;
  };

  age.secrets.pushover-app-token = {
    file = ./../secrets/pushover-app-token.age;
    mode = "550";
    owner = config.services.transmission.user;
    inherit (config.services.transmission) group;
  };

  services.transmission = {
    enable = true;
    package = pkgs-stable.transmission_4; # TODO: 4.0.6 is prohibited on some trackers
    settings = {
      download-dir = "/mnt/torrents/complete";
      incomplete-dir = "/mnt/torrents/incomplete";
      peer-port = 53150;
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
      script-torrent-done-enabled = true;
      script-torrent-done-filename = pkgs.writeShellScript "torrent-done.sh" ''
        TOKEN_USER=$(cat ${config.age.secrets.pushover-user-token.path});
        TOKEN_APP=$(cat ${config.age.secrets.pushover-app-token.path});
        MESSAGE="$TR_TORRENT_NAME finished downloading.";

        PRIORITY=0;
        SOUND="tugboat";
        TITLE="Download complete";

        TIMESTAMP=$(date +%s);

        curl -s --form-string "token=$TOKEN_APP" \
          --form-string "user=$TOKEN_USER" \
          --form-string "timestamp=$TIMESTAMP" \
          --form-string "priority=$PRIORITY" \
          --form-string "sound=$SOUND" \
          --form-string "title=$TITLE" \
          --form-string "message=$MESSAGE" \
          --form-string "url=https://torrents.zx.dev" \
          --form-string "url_title=View torrents" \
          https://api.pushover.net/1/messages.json
      '';
      utp-enabled = false;
      watch-dir = "/mnt/torrents/watch";
      watch-dir-enabled = true;
    };
    webHome = pkgs.transmissionic;
  };

  systemd.services.transmission.path = [pkgs.curl];

  networking.firewall.allowedTCPPorts = [config.services.transmission.settings.peer-port];
}

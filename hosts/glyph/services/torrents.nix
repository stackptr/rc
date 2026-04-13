{
  config,
  pkgs,
  pkgs-stable-24-05,
  ...
}: {
  services.transmission = {
    enable = true;
    package = pkgs-stable-24-05.transmission_4;
    settings = {
      download-dir = "/mnt/torrents/complete";
      incomplete-dir = "/mnt/torrents/incomplete";
      peer-port = 53150;
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
      script-torrent-done-enabled = true;
      script-torrent-done-filename = pkgs.writeShellScript "torrent-done.sh" ''
        curl -s \
          -H "Title: Transmission" \
          -d "*$TR_TORRENT_NAME* finished downloading. <https://torrents.zx.dev|View torrents>" \
          http://127.0.0.1:2586/notifications

        # Copy .mkv files to Unsorted for Jellyfin
        UNSORTED="/mnt/media/Unsorted"
        TORRENT_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

        if [ -d "$TORRENT_PATH" ]; then
          # Folder torrent: copy the folder if it contains at least one .mkv
          if find "$TORRENT_PATH" -name '*.mkv' -print -quit | grep -q .; then
            cp -r "$TORRENT_PATH" "$UNSORTED/"
            chgrp -R media "$UNSORTED/$TR_TORRENT_NAME"
            chmod -R g+rw "$UNSORTED/$TR_TORRENT_NAME"
          fi
        elif [[ "$TR_TORRENT_NAME" == *.mkv ]]; then
          # Single .mkv file
          cp "$TORRENT_PATH" "$UNSORTED/"
          chgrp media "$UNSORTED/$TR_TORRENT_NAME"
          chmod g+rw "$UNSORTED/$TR_TORRENT_NAME"
        fi
      '';
      cache-size-mb = 256;
      download-queue-enabled = true;
      download-queue-size = 5;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;
      utp-enabled = false;
      watch-dir = "/mnt/torrents/watch";
      watch-dir-enabled = true;
    };
    webHome = pkgs.transmissionic;
  };

  systemd.services.transmission.path = [pkgs.curl pkgs.findutils];
  systemd.services.transmission.serviceConfig.BindPaths = ["/mnt/media/Unsorted"];

  networking.firewall.allowedTCPPorts = [config.services.transmission.settings.peer-port];
}

{
  config,
  pkgs,
  ...
}: let
  ntfyUrl = "http://127.0.0.1:2586";
  ntfyTopic = "notifications";
in {
  age.secrets.slack-bot-token = {
    file = ./../secrets/slack-bot-token.age;
    mode = "400";
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://glyph:2586";
      listen-http = ":2586";
      enable-metrics = true;
      # Next to ntfy's own port; 9091 is Transmission's (undeclared) RPC default.
      metrics-listen-http = "127.0.0.1:2587";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [2586];

  # Posts each message on the topic to Slack as Hypha. Publishers set
  # ntfy's own fields: title (the notification preview), message (Slack
  # mrkdwn), tags (the first is the emoji), click (a link) and priority
  # (4 and up go to #alerts, the rest to #updates). See ./ntfy-to-slack.jq.
  systemd.services.ntfy-slack-relay = {
    description = "Forward ntfy notifications to Slack";
    after = ["ntfy-sh.service" "network.target"];
    requires = ["ntfy-sh.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.curl pkgs.jq];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "slack-bot-token:${config.age.secrets.slack-bot-token.path}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      set -o pipefail
      token=$(cat "$CREDENTIALS_DIRECTORY/slack-bot-token")
      # ntfy-sh is Type=simple, so it may not be listening yet when this
      # starts alongside it (e.g. during activation); retry instead of failing.
      curl -sN --retry 10 --retry-connrefused --retry-delay 1 \
        "${ntfyUrl}/${ntfyTopic}/json" |
      while IFS= read -r event; do
        payload=$(jq -c --arg alerts "#alerts" --arg updates "#updates" \
          -f ${./ntfy-to-slack.jq} <<< "$event") || continue
        [ -n "$payload" ] || continue
        curl -s https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json; charset=utf-8" \
          -d "$payload" |
          jq -r 'select(.ok | not) | "Slack rejected message: \(.error)"' >&2 || true
      done
    '';
  };
}

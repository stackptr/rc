{
  config,
  pkgs,
  ...
}: let
  ntfyUrl = "http://127.0.0.1:2586";
  ntfyTopic = "notifications";
  slackChannel = "#updates";

  ntfyToSlack = pkgs.writeShellScript "ntfy-to-slack" ''
    SLACK_TOKEN=$(cat ${config.age.secrets.slack-bot-token.path})
    TITLE="''${NTFY_TITLE:-Homelab}"
    ICON=":''${NTFY_TAGS%%,*}:"

    ${pkgs.curl}/bin/curl -s -X POST \
      "https://slack.com/api/chat.postMessage" \
      -H "Authorization: Bearer $SLACK_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$(${pkgs.jq}/bin/jq -n \
        --arg channel "${slackChannel}" \
        --arg username "$TITLE" \
        --arg icon_emoji "$ICON" \
        --arg text "$NTFY_MESSAGE" \
        '{channel: $channel, username: $username, icon_emoji: $icon_emoji, text: $text}')"
  '';
in {
  age.secrets.slack-bot-token = {
    file = ./../secrets/slack-bot-token.age;
    mode = "440";
    owner = config.services.ntfy-sh.user;
    inherit (config.services.ntfy-sh) group;
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://glyph:2586";
      listen-http = ":2586";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [2586];

  systemd.services.ntfy-slack-relay = {
    description = "Forward ntfy notifications to Slack";
    after = ["ntfy-sh.service" "network.target"];
    requires = ["ntfy-sh.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = config.services.ntfy-sh.user;
      Group = config.services.ntfy-sh.group;
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      set -o pipefail
      ${pkgs.curl}/bin/curl -sN "${ntfyUrl}/${ntfyTopic}/json" | \
      while IFS= read -r event; do
        event_type=$(${pkgs.jq}/bin/jq -r '.event // "message"' <<< "$event")
        [ "$event_type" != "message" ] && continue

        NTFY_MESSAGE=$(${pkgs.jq}/bin/jq -r '.message // empty' <<< "$event")
        NTFY_TITLE=$(${pkgs.jq}/bin/jq -r '.title // "Homelab"' <<< "$event")
        NTFY_TAGS=$(${pkgs.jq}/bin/jq -r '.tags // [] | join(",")' <<< "$event")
        [ -z "$NTFY_MESSAGE" ] && continue

        export NTFY_MESSAGE NTFY_TITLE NTFY_TAGS
        ${ntfyToSlack}
      done
    '';
  };
}

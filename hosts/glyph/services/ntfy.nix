{
  config,
  pkgs,
  ...
}: let
  ntfyUrl = "http://127.0.0.1:2586";
  ntfyTopic = "homelab";
  slackChannel = "#homelab";

  ntfyToSlack = pkgs.writeShellScript "ntfy-to-slack" ''
    SLACK_TOKEN=$(cat ${config.age.secrets.slack-bot-token.path})
    TITLE="''${NTFY_TITLE:-Homelab}"

    ${pkgs.curl}/bin/curl -s -X POST \
      "https://slack.com/api/chat.postMessage" \
      -H "Authorization: Bearer $SLACK_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$(${pkgs.jq}/bin/jq -n \
        --arg channel "${slackChannel}" \
        --arg username "$TITLE" \
        --arg text "$NTFY_MESSAGE" \
        '{channel: $channel, username: $username, text: $text}')"
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
      listen-http = "127.0.0.1:2586";
    };
  };

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
      exec ${pkgs.ntfy-sh}/bin/ntfy subscribe \
        --url ${ntfyUrl} \
        ${ntfyTopic} \
        ${ntfyToSlack}
    '';
  };
}

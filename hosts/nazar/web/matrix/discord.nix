{
  config,
  pkgs,
  ...
}: {
  services.mautrix-discord = {
    enable = true;
    settings = {
      homeserver.address = "http://localhost:8008";
      appservice = {
        database = {
          type = "postgres";
          uri = "postgres://127.0.0.1/mautrix_discord?sslmode=disable";
        };
        id = "discord";
        ephemeral_events = false; # Requires MSC2409
      };
      bridge = {
        private_chat_portal_meta = true;
        encryption = {
          allow = true;
          default = true;
          require = true;
        };
        provisioning = {
          shared_secret = "disable";
        };
        username_template = "discord_{{.}}";
        displayname_template = "{{or .GlobalName .Username}}{{if .Bot}} (bot){{end}}";
        channel_name_template = "{{if or (eq .Type 3) (eq .Type 4)}}{{.Name}}{{else}}#{{.Name}}{{end}}";
        guild_name_template = "{{.Name}}";
        double_puppet_server_map = {};
        login_shared_secret_map = {};
        command_prefix = "!discord";
        permissions."*" = "relay";
      };
    };
  };
  services.dendrite.settings.app_service_api.config_files = [
    "/var/lib/mautrix-discord/discord-registration.yaml"
  ];
}

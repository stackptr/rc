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
      };
    };
  };
  services.dendrite.settings.app_service_api.config_files = [
    "/var/lib/mautrix-discord/discord-registration.yaml"
  ];
}

{
  config,
  pkgs,
  ...
}: {
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "esphome"
      "met"
      "radio_browser"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      auth_oidc
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
      auth_oidc = {
        client_id = "5717cfe0-7251-466b-a067-a7dd3a1c4f81";
        discovery_url = "https://id.zx.dev/.well-known/openid-configuration";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [8123];

  # Home-Assistant currently uses an EOL'd version of OpenSSL
  # See:
  # - https://github.com/project-chip/connectedhomeip/issues/25688
  # - https://github.com/NixOS/nixpkgs/issues/269713
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];
}

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
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};
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

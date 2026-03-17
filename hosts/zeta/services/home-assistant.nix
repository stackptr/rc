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
      # Required by ai_task → camera import chain in service descriptions
      "camera"
      "mobile_app"
    ];
    config = {
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "100.64.0.0/10"
        ];
      };
      mobile_app = {};
    };
  };
  networking.firewall.allowedTCPPorts = [8123];
}

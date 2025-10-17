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
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "100.64.0.0/10"
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [8123];
}

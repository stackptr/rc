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
      "zeroconf"
    ];
    config = {
      # No `http` block: since 2026.8 the HTTP server settings (including
      # Trust X-Forwarded-For and Trusted proxies, which spore's nginx needs)
      # live in the UI under Settings > System > Network. YAML is imported
      # once and ignored afterwards.
      mobile_app = {};
      zeroconf = {};
    };
  };
  networking.firewall.allowedTCPPorts = [8123];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}

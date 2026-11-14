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
      # Device integrations, set up in the UI. Listing them here installs
      # their Python dependencies; without it the config flow fails.
      "lutron_caseta" # Local LEAP client of the Smart Bridge; HomeKit stays paired
      "midea" # Local; save each device's V3 token and key, Midea is retiring the cloud lookup
      "lg_thinq" # Cloud push; needs a ThinQ Connect personal access token
      "nest" # Device Access (SDM) API over Google Cloud Pub/Sub
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

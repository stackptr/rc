{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alloy.nix
    ./home-assistant.nix
    ./homebridge.nix
    ./znc.nix
  ];
  services.openssh.enable = true;
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = ["systemd"];
    # Scraped by Prometheus on glyph over the tailnet only.
    openFirewall = true;
    firewallFilter = "-i tailscale0 -p tcp -m tcp --dport 9100";
  };
  programs.mosh.enable = true;
  programs.git.enable = true;
  programs.gnupg.agent.enable = true;
}

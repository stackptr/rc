{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alloy.nix
    ./gatus.nix
    ./home-assistant.nix
    ./homebridge.nix
    ./znc.nix
  ];
  services.openssh.enable = true;
  services.tailscale = {
    enable = true;
    # No Tailscale SSH: it answers port 22 on the tailnet address before
    # sshd, bypassing authorized_keys. The setting persists in tailscaled's
    # state, so it has to be turned off explicitly, not just left out of up.
    extraSetFlags = ["--ssh=false"];
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

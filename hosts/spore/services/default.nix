{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./db.nix
    ./grafana.nix
    ./homepage-dashboard.nix
    ./mastodon.nix
    ./web
  ];

  age.secrets.tailscale-auth-key = {
    file = ../secrets/tailscale-auth-key.age;
    mode = "440";
    owner = config.services.golink.user;
    inherit (config.services.golink) group;
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = ["systemd"];
  };

  services.glances = {
    inherit (config.services.homepage-dashboard) enable;
  };

  services.golink = {
    enable = true;
    tailscaleAuthKeyFile = config.age.secrets.tailscale-auth-key.path;
    package = pkgs.buildGo125Module {
      pname = "golink";
      inherit (pkgs.golink) version src ldflags;
      vendorHash = "sha256-M3Qm25KF6gWtp3K1SigLucgrIJ+5KokMq+Bp7XXaE+o=";
    };
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;
}

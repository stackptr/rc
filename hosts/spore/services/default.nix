{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./authelia.nix
    ./db.nix
    ./homepage-dashboard.nix
    ./mastodon.nix
    ./profile.nix
    ./web
    ./infrastructure
  ];

  age.secrets.tailscale-auth-key = {
    file = ../secrets/tailscale-auth-key.age;
    mode = "440";
    owner = config.services.golink.user;
    group = config.services.golink.group;
  };
  services.golink = {
    enable = true;
    tailscaleAuthKeyFile = config.age.secrets.tailscale-auth-key.path;
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;
}

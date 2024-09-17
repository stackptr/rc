{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./matrix
    ./nginx
    ./authelia.nix
    ./db.nix
    ./homepage-dashboard.nix
    ./mastodon.nix
    ./profile.nix
  ];
}

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
    ./mastodon.nix
    ./profile.nix
  ];
}

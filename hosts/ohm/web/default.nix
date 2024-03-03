{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./nginx
    ./authelia.nix
    ./db.nix
    ./mastodon.nix
    ./matrix.nix
    ./profile.nix
  ];
}

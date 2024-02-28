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
  ];
}

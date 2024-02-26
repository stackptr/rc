{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./nginx
    ./db.nix
    ./apps.nix
  ];
}

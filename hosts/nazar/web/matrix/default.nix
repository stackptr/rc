{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dendrite.nix
    ./heisenbridge.nix
  ];
}

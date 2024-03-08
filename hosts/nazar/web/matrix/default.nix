{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dendrite.nix
  ];
}

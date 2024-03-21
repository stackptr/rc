{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system.nix
  ];
  system.defaults.dock = {
    tilesize = 49;
    largesize = 92;
  };
}

{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system.nix
  ];
  system.defaults.dock = {
    tilesize = 42;
    largesize = 86;
  };
}

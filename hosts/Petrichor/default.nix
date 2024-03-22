{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./system.nix
  ];
  homebrew.casks = ["elgato-stream-deck"];
  system.defaults.dock = {
    tilesize = 49;
    largesize = 92;
  };
}

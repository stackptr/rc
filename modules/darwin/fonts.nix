{
  config,
  pkgs,
  lib,
  ...
}: {
  fonts.packages = [
    pkgs.nerd-fonts.meslo-lg # Supplies MesloLGSDZ: Line Gap Small, Dotted Zero
  ];
}

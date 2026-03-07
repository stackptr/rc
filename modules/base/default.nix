# Base configuration shared across all systems
{
  imports = [
    ./gc.nix
    ./nix-config.nix
    ./unfree-packages.nix
  ];
}

# Base configuration shared across all systems
{
  imports = [
    ./gc.nix
    ./host.nix
    ./nix-config.nix
    ./unfree-packages.nix
  ];
}

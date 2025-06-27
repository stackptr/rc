# Base configuration shared across all systems
{
  imports = [
    ./nix-config.nix
    ./secrets-validation.nix
    ./unfree-packages.nix
  ];
}

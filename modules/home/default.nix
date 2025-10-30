# Home Manager-specific configuration modules
{
  imports = [
    ./programs
    ./development.nix
    ./git.nix
    ./utilities.nix
  ];
}

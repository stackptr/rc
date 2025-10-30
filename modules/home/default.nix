# Home Manager-specific configuration modules
{
  imports = [
    ./programs
    ./development.nix
    ./git.nix
    ./ssh.nix
    ./utilities.nix
  ];
}

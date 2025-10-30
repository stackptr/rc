# Home Manager-specific configuration modules
{
  imports = [
    ./programs
    ./development.nix
    ./editor.nix
    ./git.nix
    ./ssh.nix
    ./utilities.nix
  ];
}

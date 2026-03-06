# Home Manager-specific configuration modules
{
  imports = [
    ./programs
    ./development.nix
    ./editor.nix
    ./scm.nix
    ./ssh.nix
    ./utilities.nix
  ];
}

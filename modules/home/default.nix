# Home Manager-specific configuration modules
{
  imports = [
    ./programs
    ./development.nix
    ./editor.nix
    ./gpg.nix
    ./scm.nix
    ./ssh.nix
    ./utilities.nix
  ];
}

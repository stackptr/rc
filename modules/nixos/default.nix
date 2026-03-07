# NixOS-specific configuration modules
{
  imports = [
    ./llm
    ./web
    ./boot.nix
    ./filebrowser-quantum.nix
    ./restic-backup.nix
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}

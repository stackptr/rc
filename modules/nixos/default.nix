# NixOS-specific configuration modules
{
  imports = [
    ./llm
    ./web
    ./boot.nix
    ./deploy-marker.nix
    ./filebrowser-quantum.nix
    ./node-exporter.nix
    ./obsidian-sync.nix
    ./restic-backup.nix
    ./users.nix
    ./ssh.nix
    ./sudo.nix
  ];
}

{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./../../../../modules/services/mautrix-discord.nix
    ./dendrite.nix
    ./heisenbridge.nix
    ./discord.nix
  ];
}

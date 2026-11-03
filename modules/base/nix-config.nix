# Nix-specific configuration settings
{
  inputs,
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [username];
      # attic on glyph, published through spore as cache.zx.dev. glyph
      # overrides this with its local address (hosts/glyph/services/attic.nix).
      extra-substituters = lib.mkDefault ["https://cache.zx.dev/main"];
      extra-trusted-public-keys = ["main:mu0jkxdJTGWC3djDSEQb3rvZgqlhA8WVMulcTo5IW6c="];
    };
  };

  programs.zsh.enable = true;
}

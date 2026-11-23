# Nix-specific configuration settings
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  nix = {
    # Flake inputs only, and not self: self's store path changes on every
    # commit, and non-flake inputs (the Homebrew taps) on nearly every update,
    # either of which would change every host's system
    registry =
      lib.mapAttrs (_: value: {flake = value;})
      (lib.filterAttrs (name: value: name != "self" && value ? outputs) inputs);
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # attic on glyph, published through spore as cache.zx.dev. glyph
      # overrides this with its local address (hosts/glyph/services/attic.nix).
      extra-substituters = lib.mkDefault ["https://cache.zx.dev/main"];
      extra-trusted-public-keys = ["main:mu0jkxdJTGWC3djDSEQb3rvZgqlhA8WVMulcTo5IW6c="];
    };
  };

  programs.zsh.enable = true;
}

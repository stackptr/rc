# Packages taken from an older nixpkgs while they fail to build on the one in
# flake.lock. Each entry in ./pinned.json names a top-level attribute and the
# nixpkgs revision it last built on (copied from flake.lock by
# scripts/pin-package), and has an open `workaround` issue saying what broke
# and when the pin can go. Each pin keeps its own revision, so pinning a second
# package never moves the first.
final: prev: let
  nixpkgsAt = pin:
    import (builtins.fetchTree {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      inherit (pin) rev narHash;
    }) {
      inherit (prev.stdenv.hostPlatform) system;
      # Not all of prev.config: its newer options, even null ones like
      # replaceStdenv, break an older nixpkgs
      config = {inherit (prev.config) allowUnfree allowUnfreePredicate;};
    };
in
  builtins.mapAttrs (name: pin: (nixpkgsAt pin).${name})
  (builtins.fromJSON (builtins.readFile ./pinned.json))

# opencode 2.2.5's node_modules hash in nixos-unstable is wrong on Linux, so
# glyph fails to build: bun now produces a different tree there. nixpkgs
# master splits the hash per platform; this is its Linux value. The guard
# makes this a no-op once nixpkgs carries any other hash, so a later version
# bump isn't given a stale one. Drop once nixos-unstable has the per-platform
# hashes.
final: prev: let
  brokenHash = "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=";
in {
  opencode =
    if prev.stdenv.hostPlatform.isLinux && prev.opencode.node_modules.outputHash == brokenHash
    then
      prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        };
      })
    else prev.opencode;
}

# Host-specific secrets with principle of least privilege
# Each host only has access to its own secrets plus admin keys
let
  globalSecrets = import ./secrets/default.nix;
  glyphSecrets = import ./secrets/glyph.nix;
  sporeSecrets = import ./secrets/spore.nix;
  zetaSecrets = import ./secrets/zeta.nix;
in
  globalSecrets
  // glyphSecrets
  // sporeSecrets
  // zetaSecrets

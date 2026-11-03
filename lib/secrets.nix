# Host-specific secrets with principle of least privilege
# Each host only has access to its own secrets plus admin keys
let
  globalSecrets = import ./secrets/default.nix;
  adminSecrets = import ./secrets/admin.nix;
  glyphSecrets = import ./secrets/glyph.nix;
  lobtopSecrets = import ./secrets/lobtop.nix;
  sporeSecrets = import ./secrets/spore.nix;
  stromaSecrets = import ./secrets/Stroma.nix;
  zetaSecrets = import ./secrets/zeta.nix;
  homeSecrets = import ./secrets/home.nix;
in
  globalSecrets
  // adminSecrets
  // glyphSecrets
  // lobtopSecrets
  // sporeSecrets
  // stromaSecrets
  // zetaSecrets
  // homeSecrets

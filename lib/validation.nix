# Validation functions for Nix configuration patterns
{lib, ...}: let
  # Validate hostname format
  validateHostname = hostname:
    lib.assertMsg
    (builtins.match "^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$" hostname != null)
    "Hostname '${hostname}' must start with a letter, contain only alphanumeric characters and hyphens, and not end with a hyphen";

  # Validate username format
  validateUsername = username:
    lib.assertMsg
    (builtins.match "^[a-z][a-z0-9_-]*$" username != null)
    "Username '${username}' must start with a lowercase letter and contain only lowercase letters, numbers, hyphens, and underscores";

  # Validate system architecture
  validateSystem = system:
    lib.assertMsg
    (builtins.elem system ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"])
    "System '${system}' must be one of: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin";

  # Validate that required files exist for a host
  validateHostFiles = {
    hostname,
    hostType,
  }: let
    hostPath = ./../hosts/${hostname};
    requiredFiles = {
      nixos = ["default.nix" "hardware.nix"];
      darwin = ["default.nix"];
    };
    files = requiredFiles.${hostType} or [];
  in
    lib.all (file: builtins.pathExists (hostPath + "/${file}")) files
    || throw "Host '${hostname}' missing required files: ${lib.concatStringsSep ", " files}";

  # Validate service configuration structure
  validateServiceConfig = {
    services,
    hostname,
  }: let
    hasValidStructure = services != null && builtins.isAttrs services;
    hasRequiredServices = builtins.hasAttr "openssh" services && services.openssh.enable or false;
  in
    lib.assertMsg hasValidStructure "Host '${hostname}' must have valid services configuration"
    && lib.assertMsg hasRequiredServices "Host '${hostname}' must enable openssh service";

  # Validate secrets configuration
  validateSecrets = {
    secrets,
    hostname,
  }: let
    hasValidSecrets = secrets == null || (builtins.isAttrs secrets && builtins.all (secret: builtins.hasAttr "file" secret) (builtins.attrValues secrets));
  in
    lib.assertMsg hasValidSecrets "Host '${hostname}' secrets must have valid 'file' attribute";
in {
  inherit
    validateHostname
    validateUsername
    validateSystem
    validateHostFiles
    validateServiceConfig
    validateSecrets
    ;
}

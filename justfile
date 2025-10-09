# Build the system config and switch to it when running `just` with no args
default: switch

hostname := `hostname | cut -d "." -f 1`

[macos]
switch host=hostname:
  nh darwin switch .#darwinConfigurations.{{host}}

[linux]
switch host=hostname:
  nh os switch .#nixosConfigurations.{{host}}

update:
  nix flake update --commit-lock-file

switch-remote target-host build-host="localhost":
  nixos-rebuild switch --flake .#{{target-host}} --target-host root@{{target-host}} --build-host {{build-host}}

# Development and testing recipes

# Validate a specific host configuration without building
check-host host:
  @echo "🔍 Checking host configuration: {{host}}"
  nix eval .#nixosConfigurations.{{host}}.config.system.name 2>/dev/null && echo "✅ NixOS host {{host}} is valid" || \
  nix eval .#darwinConfigurations.{{host}}.config.system.name 2>/dev/null && echo "✅ Darwin host {{host}} is valid" || \
  echo "❌ Host {{host}} not found or invalid"

# Test individual service configuration
test-service host service:
  @echo "🧪 Testing service {{service}} on {{host}}"
  nix eval .#nixosConfigurations.{{host}}.config.services.{{service}}.enable 2>/dev/null && echo "✅ Service {{service}} is enabled" || \
  echo "❌ Service {{service}} not found or disabled"

# Validate host secrets configuration
secrets-validate host:
  @echo "🔐 Validating secrets for host: {{host}}"
  @if [ -d "hosts/{{host}}/secrets" ]; then \
    echo "Found secrets directory for {{host}}"; \
    ls -la hosts/{{host}}/secrets/; \
    nix eval .#nixosConfigurations.{{host}}.config.age.secrets --apply builtins.attrNames 2>/dev/null || \
    nix eval .#darwinConfigurations.{{host}}.config.age.secrets --apply builtins.attrNames 2>/dev/null || \
    echo "No secrets configured"; \
  else \
    echo "No secrets directory found for {{host}}"; \
  fi

# Build host configuration without switching
build-host host:
  @echo "🏗️ Building host configuration: {{host}}"
  nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel 2>/dev/null && echo "✅ NixOS build successful" || \
  nix build .#darwinConfigurations.{{host}}.system 2>/dev/null && echo "✅ Darwin build successful" || \
  echo "❌ Build failed for {{host}}"

# Check specific service configurations
check-services:
  @echo "🔍 Checking individual service configurations..."
  nix flake check --print-build-logs | grep -E "(spore|glyph)-(nginx|authelia|postgresql|samba|transmission)" || echo "Service checks completed"

# List all available hosts
list-hosts:
  @echo "📋 Available hosts:"
  @echo "NixOS hosts:"
  @nix eval .#nixosConfigurations --apply builtins.attrNames --json | jq -r '.[]' | sed 's/^/  - /'
  @echo "Darwin hosts:"
  @nix eval .#darwinConfigurations --apply builtins.attrNames --json | jq -r '.[]' | sed 's/^/  - /'

# Quick configuration syntax check
syntax-check:
  @echo "📝 Checking flake syntax..."
  nix flake check --dry-run

# Show host information
host-info host:
  @echo "ℹ️ Host information for: {{host}}"
  @echo "System type:"
  @nix eval .#nixosConfigurations.{{host}}.config.nixpkgs.system 2>/dev/null | tr -d '"' || \
   nix eval .#darwinConfigurations.{{host}}.config.nixpkgs.system 2>/dev/null | tr -d '"' || \
   echo "Unknown"
  @echo "Services enabled:"
  @nix eval .#nixosConfigurations.{{host}}.config.services --apply '(services: builtins.filter (name: services.${name}.enable or false) (builtins.attrNames services))' --json 2>/dev/null | jq -r '.[]' | head -10 | sed 's/^/  - /' || \
   echo "  Unable to determine services"

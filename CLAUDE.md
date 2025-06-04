# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Nix flake-based system configuration repository that manages multiple hosts across NixOS and macOS platforms:

- **NixOS hosts**: `zeta` (ARM/Pi4), `glyph` (x86_64 NAS/homelab), `spore` (x86_64 VPS)
- **macOS hosts**: `Rhizome` (personal laptop), `Petrichor` (work laptop)

The configuration is organized into:
- `hosts/`: Host-specific configurations
- `modules/`: Shared modules split between `base.nix` (common), `nixos.nix` (Linux-specific), and `darwin/` (macOS-specific)
- `home/`: Home-manager configurations
- `lib/hosts.nix`: Host configuration factory functions
- `overlays/`: Package overlays

## Common Commands

**Build and switch to configuration:**
```bash
just                    # Switch current host
just switch hostname    # Switch specific host
```

**Using nh (preferred method):**
```bash
nh os switch .#hostname        # Linux
nh darwin switch .#hostname    # macOS
```

**Direct rebuild commands:**
```bash
sudo darwin-rebuild switch --flake .#hostname  # macOS
nixos-rebuild switch --flake .#hostname        # Linux
```

**Cross-compilation for memory-constrained hosts:**
```bash
# Build spore config on glyph due to memory constraints
nixos-rebuild switch --flake .#spore --target-host root@spore --build-host localhost
```

**Flake management:**
```bash
nix flake update --commit-lock-file
```

**Development shell:**
```bash
nix develop  # Provides agenix, cachix, just
```

## Key Configuration Details

- Linux username: `mu`
- macOS username: `corey`
- All hosts use SSH key authentication with keys defined in `lib/keys.nix`
- Secrets managed via agenix with host-specific access controls
- Home-manager integrated for user-space configuration
- macOS hosts use nix-homebrew for Homebrew integration

## Secrets Organization

Secrets are organized using the principle of least privilege:
- `lib/secrets/` - Host-specific secrets modules
- Each host only has access to its own secrets plus admin keys (Petrichor/Rhizome)
- Global secrets (if any) are defined in `lib/secrets/default.nix`

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`.

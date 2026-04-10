# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Nix flake-based system configuration repository that manages multiple hosts across NixOS and macOS platforms:

- **NixOS hosts**: `zeta` (ARM/Pi4), `glyph` (x86_64 NAS/homelab), `spore` (x86_64 VPS)
- **macOS hosts**: `Rhizome` (personal laptop)

The configuration is organized into:
- `hosts/`: Host-specific configurations
- `modules/`: Shared modules with focused organization:
  - `base.nix` - Base configuration (imports nix-config + unfree packages)
  - `nixos.nix` - NixOS configuration (imports nixos/ submodules)
  - `nixos/` - NixOS-specific modules (users, ssh, sudo)
  - `darwin/` - macOS-specific modules
- `home/`: Home-manager configurations
- `lib/hosts.nix`: Simplified host builder functions (`mkNixosHost`, `mkDarwinHost`)
- `overlays/`: Package overlays and customizations (managed via `overlays/default.nix`)
- `packages/`: Custom package definitions for applications not in nixpkgs

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

**Checking changes before committing:**
```bash
nix-flake eval nixosConfigurations.hostname.config.system.build.toplevel.drvPath
```
Evaluates a host's configuration without building it. Catches option conflicts and type errors fast — run this after editing any NixOS module or host config.

**Flake management:**
```bash
nix flake update --commit-lock-file
```

**Development shell:**
```bash
nix develop  # Provides agenix, graphite-cli, just
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
- Each host only has access to its own secrets plus admin keys
- Global secrets (if any) are defined in `lib/secrets/default.nix`

## Package and Overlay Management

Custom packages and overlays are organized for clarity:
- `packages/*/package.nix` - Custom package definitions
- `overlays/custom-packages.nix` - Overlay exposing custom packages
- `overlays/gitify.nix`, `overlays/whatsapp-for-mac.nix` - App-specific version overrides
- `overlays/default.nix` - Consolidates all overlays for easy management

## Branching

- Branches should be scoped to a single host whenever possible. This keeps deploys independent and reduces risk of cross-host breakage.
- Branch naming: `host/type-short-slug` for host-scoped changes, `type-short-slug` for top-level changes.
  - `host/` is the hostname (e.g. `glyph/`, `spore/`, `Rhizome/`, `zeta/`)
  - `type` is one of `feat`, `fix`, `chore`, `refactor`
  - The slug should be succinct — 2 to 4 words max (e.g. `fix-gc-options`, not `fix-gc-options-from-base-module-conflicting-definitions`)
  - Examples: `spore/fix-gc-options`, `Rhizome/feat-launchd-service`, `chore-update-flake-inputs`, `feat-add-ci-eval`
- Always pass the branch name explicitly to `gt create` — if omitted, Graphite auto-generates one from the commit message and may prepend a user prefix:
  ```bash
  gt create spore/fix-gc-options --message "fix(spore): ..."
  ```

## Nix Commands

Never use `nix <subcommand> .#<output>` — the `#` causes permission prompt failures. Use wrapper scripts instead:

| Instead of | Use |
|---|---|
| `nix build .#foo` | `nix-flake build foo` |
| `nix eval .#foo` | `nix-flake eval foo` |
| `nix eval nixpkgs#foo` | `nixpkgs-eval foo` |
| `nix run nixpkgs#foo` | `nixpkgs-run foo` |
| `nix shell nixpkgs#foo` | `nixpkgs-shell foo` |

## Common Patterns

**Overriding a shared base module option in a host config:**
Use `lib.mkForce` when a host needs to diverge from a value set in a shared module (e.g. `modules/base/`). Without it, Nix will error on conflicting definitions.
```nix
# modules/base/gc.nix sets nix.gc.dates = "weekly"
# hosts/spore/default.nix overrides it:
nix.gc.dates = lib.mkForce "daily";
```

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`.

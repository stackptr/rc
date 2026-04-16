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
# NixOS hosts:
nix-flake eval nixosConfigurations.hostname.config.system.build.toplevel.drvPath
# macOS hosts:
nix-flake eval darwinConfigurations.Rhizome.system.drvPath
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

**agenix workflow:**
```bash
# Edit an existing secret (must be on a host with access, or have the deploy key):
agenix -e hosts/spore/secrets/some-secret.age

# Add a new secret:
# 1. Add an entry to lib/secrets/<host>.nix with the appropriate publicKeys
# 2. Run: agenix -e hosts/<host>/secrets/<name>.age
# 3. Reference it in the host config via age.secrets.<name>.file

# Rekey all secrets after adding a new host key:
agenix --rekey
```
- Keys are defined in `lib/keys.nix` — each host's key is read from `hosts/<host>/key.pub`
- A new host must have its key added to `lib/keys.nix` and any relevant secrets files before it can decrypt them

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

**Submitting PRs:**
- Title format: `type: short description` — e.g. `fix: spore gc options`, `chore: update CLAUDE.md`, `feat: add ci eval job`
- Description should include a brief summary of what changed and what to test/verify

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

**Amending the current branch:**
Use `gt modify` instead of `git commit --amend` to keep the Graphite stack consistent:
```bash
git add <files>
gt modify --no-edit        # amend without changing message
gt modify -m "new message" # amend with new message
```

**`lib.mkForce` vs `lib.mkDefault`:**
- `lib.mkForce value` — host wins over any module default. Use when a host must diverge from a shared module.
- `lib.mkDefault value` — module loses to any host override. Use in shared modules to set a default that hosts can freely override without `mkForce`.

**Overriding a shared base module option in a host config:**
Use `lib.mkForce` when a host needs to diverge from a value set in a shared module (e.g. `modules/base/`). Without it, Nix will error on conflicting definitions.
```nix
# modules/base/gc.nix sets nix.gc.dates = "weekly"
# hosts/spore/default.nix overrides it:
nix.gc.dates = lib.mkForce "daily";
```

## Environment Awareness

- Before running commands like `ssh`, `nixos-rebuild`, or anything that targets a specific host, check which host Claude Code is running on (`hostname`) to avoid targeting the current machine unintentionally.
- The current host is typically `glyph` (NixOS desktop) or `Rhizome` (macOS laptop).

## Learning and Memory

- After arriving at a working solution through trial and error, proactively ask whether the finding should be recorded in CLAUDE.md (or Basic Memory) for future sessions.

## Commit Identity

When making git commits, always use a distinct agent identity and disable GPG signing (which requires an interactive passphrase and will hang):

```bash
git commit \
  -c commit.gpgsign=false \
  -c user.name="Claude Code" \
  -c user.email="claude-code@noreply.anthropic.com" \
  -m "..."
```

This applies to all `git commit` invocations, including via `gt modify`. For `gt modify`, pass the `-c` flags via `GIT_CONFIG_COUNT` env vars or use `git commit` directly when amending:

```bash
GIT_CONFIG_COUNT=3 \
  GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false \
  GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1="Claude Code" \
  GIT_CONFIG_KEY_2=user.email GIT_CONFIG_VALUE_2="claude-code@noreply.anthropic.com" \
  gt modify --no-edit
```

Commits made this way will appear as **Unverified** on GitHub, clearly distinguishing agent-authored commits from human-authored ones.

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`.

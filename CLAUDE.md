# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Nix flake-based system configuration repository that manages multiple hosts across NixOS and macOS platforms:

- **NixOS hosts**: `zeta` (ARM/Pi4), `glyph` (x86_64 NAS/homelab), `spore` (x86_64 VPS)
- **macOS hosts**: `Rhizome` (personal laptop), `Stroma` (Mac Studio), `lobtop` (work laptop)

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

**Build and switch to configuration** (only when asked; see Guardrails):
```bash
just                              # Switch current host
just switch hostname              # Switch specific host
just switch-remote spore          # Build on this host, deploy to spore (it's memory-constrained)
```

**Checking changes before committing:**
```bash
# NixOS hosts:
nix-flake eval nixosConfigurations.hostname.config.system.build.toplevel.drvPath
# macOS hosts (Rhizome, Stroma, lobtop):
nix-flake eval darwinConfigurations.hostname.system.drvPath
```
Evaluates a host's configuration without building it. Catches option conflicts and type errors fast — run this after editing any NixOS module or host config.

**Flake management:**
```bash
nix flake update --commit-lock-file
```

**Development shell:**
```bash
nix develop  # Provides agenix, just
```

Agent conversations in Zed do not run inside the devShell. To invoke devShell tools from within a Claude Code session (e.g. `entire`, `agenix`), prefix commands with `direnv exec . <command>`:
```bash
direnv exec . entire version
direnv exec . agenix -e hosts/spore/secrets/foo.age
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

- Scope branches to a single host whenever possible. This keeps deploys independent and reduces the risk of cross-host breakage.
- Branch naming: `scope/type-short-slug`, where scope is the hostname (`glyph`, `spore`, `zeta`, `Rhizome`, `Stroma`, `lobtop`) or `home` for shared home-manager changes. Top-level or cross-cutting changes drop the scope: `type-short-slug`.
  - `type` is one of `feat`, `fix`, `chore`, `refactor`; the slug is 2 to 4 words.
  - Examples: `spore/fix-gc-options`, `home/feat-claude-memory`, `chore-update-flake-inputs`.
- PR title: `type(scope): short description`, with the scope omitted for top-level changes, e.g. `fix(spore): gc options`, `chore: update flake inputs`. PRs are squash-merged, so the title becomes the commit message.
- PR description: a brief summary of what changed and what to test or verify.

## Sandboxed sessions

If `nix-flake` isn't on PATH, you're in a sandboxed session without my tooling, and Nix may not be installed. Don't try to evaluate or build. Make the change, push the branch, and open a PR: CI evaluates and builds glyph, spore, zeta, and Rhizome. CI doesn't cover Stroma or lobtop, so say when a change touches them and needs a local `nix-flake eval`.

## Common Patterns

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

## Monitoring Stack

The homelab runs a Grafana LGTM-lite stack for observability. Use it first when investigating service failures, slow response times, disk issues, or any situation where you'd otherwise reach for `journalctl` or SSH into a host to check a service.

- **Grafana** (glyph:3000, `grafana.zx.dev` via spore) — dashboards, Explore, alerting; config in `hosts/glyph/services/grafana.nix`. The image renderer (headless Chromium, localhost:8081) backs `get_panel_image`.
- **Loki** (glyph:3100) — log aggregation from glyph, spore, zeta; 30 days retained
- **Prometheus** (glyph:9099) — metrics from glyph, spore, zeta; 90 days retained
- **Alert rules** — provisioned from `hosts/glyph/services/grafana-alerts.nix` (folder "Alerts", routed to Slack). Add rules there, not in the UI.
- **Gatus** (zeta:8080, `status.zx.dev` behind Pocket ID) — out-of-band watchdog in `hosts/zeta/services/gatus.nix`. Every minute it checks glyph (reachability, Postgres, Prometheus freshness, Loki ingestion, and Grafana health through spore's proxy) and spore (reachability), plus the `zx.dev` cert hourly, and posts to Slack itself, so it still alerts when glyph or Grafana is down.
- **Dashboards** — provisioned JSON in `hosts/glyph/services/dashboards/`: Node, ZFS, Log Explorer, PostgreSQL, Disk Health (SMART), Systemd Units, nginx.

**MCP access:** The `grafana` MCP server is registered in mcpjungle on glyph at `http://127.0.0.1:8095/mcp`. It exposes tools for LogQL (Loki), PromQL (Prometheus), and dashboard access. Use it instead of `journalctl` for anything beyond a quick one-liner. It runs read-only (`--disable-write` in `modules/nixos/llm/grafana-mcp.nix`), so change alert rules and dashboards in the flake, not through the MCP.

### Loki label schema

All logs carry these labels, queryable with `{label="value"}` in LogQL:

| Label | Source journal field | Example values |
|---|---|---|
| `host` | Static (Alloy external_labels) | `glyph`, `spore`, `zeta` |
| `unit` | `_SYSTEMD_UNIT` | `navidrome.service`, `nginx.service` |
| `priority` | `PRIORITY` | `0`–`7` (0=emerg, 3=err, 4=warn, 6=info, 7=debug) |
| `app` | `SYSLOG_IDENTIFIER` | `navidrome`, `nginx`, `kernel` |

**Alloy journal label naming:** In `discovery.relabel` rules for `loki.source.journal`, the source label prefix is `__journal_` + the field name lowercased. Fields with a leading underscore (e.g. `_SYSTEMD_UNIT` → `_systemd_unit`) produce a double underscore (`__journal__systemd_unit`). Fields without one (e.g. `PRIORITY`, `SYSLOG_IDENTIFIER`) produce a single underscore (`__journal_priority`, `__journal_syslog_identifier`).

**Alloy reads nothing from the journal:** if a host stops shipping logs while `alloy.service` is active and logs no errors, check `curl -s localhost:12345/metrics | grep loki_source_journal_target_lines_total` on that host. If it stays at 0 while `journalctl` works, alloy's libsystemd can't open the journal files. nixpkgs links alloy against `systemdLibs`, which is built without zstd, and journald writes zstd-compressed files. `overlays/grafana-alloy.nix` relinks it against full systemd. Deleting alloy's saved positions doesn't help.

**Common LogQL patterns:**
```logql
# All errors and above from a specific service
{host="glyph", unit="navidrome.service", priority=~"[0-3]"}

# All warnings and above across spore
{host="spore", priority=~"[0-4]"}

# nginx error log on spore
{host="spore", app="nginx"}

# nginx access logs on spore (JSON: vhost, method, uri, status, bytes,
# request_time, upstream_time, upstream_status, remote_addr, user_agent)
{host="spore", app="nginx_access"} | json | status >= 500

# p95 latency per vhost over 5m
quantile_over_time(0.95, {host="spore", app="nginx_access"} | json | unwrap request_time [5m]) by (vhost)

# Recent errors across all hosts
{priority=~"[0-3]"} |= "error"
```

To summarise a noisy stream, use grafana-mcp's `query_loki_patterns` with a stream selector such as `{host="glyph", unit="jellyfin.service"}`. It groups similar lines and counts each group. Patterns are held in Loki's memory, so they only cover logs since Loki last restarted.

### Deploys

Check deploys first when something regressed. Every activation on glyph, spore or zeta logs one line, whichever path ran it. The Deploy workflow also writes its full deploy-rs output into the target host's journal. Dashboards show both as a purple "Deploys" annotation.

```logql
# Every activation: action (switch/test), flake revision ("<rev>-dirty" for
# local uncommitted builds), system store path. `nh os switch` logs action=test.
{app="nixos-deploy"}

# Deploy workflow output for a host; the last line is the summary with the
# run URL, at priority err if the deploy failed
{host="spore", app="deploy-rs"}

# Unit restarts, failures and activation errors from switch-to-configuration
# (only for `just switch-remote`, which runs it as a systemd-run unit)
{unit="nixos-rebuild-switch-to-configuration.service"}
```

On the host, `nixos-version --configuration-revision` gives the deployed revision.

### Prometheus jobs and exporters

Every scraped series carries `instance` and an identical `host` label (`glyph`, `spore`, `zeta`), so `{host="glyph"}` selects the same machine in PromQL and LogQL. OTLP-pushed series (Open WebUI) have `instance` only.

| Job | Port | Host | Covers |
|---|---|---|---|
| `node` | 9100 | glyph, spore, zeta | CPU, memory, disk, network, systemd unit states, restarts (`node_systemd_service_restart_total`), start times, timer last-trigger |
| `zfs` | 9134 | glyph | Pool health, ARC hit ratio, pool space |
| `postgres` | 9187 | glyph | Connections, query throughput, vacuum, per-DB stats |
| `smartctl` | 9633 | glyph | SMART status, temperature, sector errors (sda–sdd); NVMe wear, spare, media errors, critical warning (nvme0) |
| `nginx` | 9113 | spore | Request rate, active connections, handled/dropped |
| `navidrome` | 4533/metrics | glyph | `db_model_totals` (library size), `media_scan_last`, HTTP request count/latency |
| `prometheus` | 9099 | glyph | Prometheus self-metrics (TSDB, scrape health) |
| `loki` | 3100 | glyph | Loki ingestion and query metrics |
| `coredns` | 9153 | glyph | DNS queries, responses by rcode, forward latency (`ts.zx.dev` zone) |
| `ntfy` | 2587 | glyph | Messages published, subscribers, HTTP requests |
| `gatus` | 8080 | zeta | `gatus_results_*` per watchdog endpoint: success, duration, certificate expiry |
| `open-webui` | push (OTLP) | glyph | `http_server_requests_total`, `http_server_duration_*`, `webui_users_*`; pushed to Prometheus's OTLP receiver, not scraped, so no `up` series |

**Picking a port on glyph:** grep the repo, and also check service defaults that aren't declared in Nix. Transmission's RPC listens on 9091 by default (`torrents.zx.dev` proxies to it), so a new exporter on 9091 fails with "address already in use".

**smartctl exporter and late devices:** v0.14.0 registers its metric list at startup from whatever disks it can read then. If a disk becomes readable later (NVMe ACL applied after start, a drive waking from standby), every scrape fails with `collected metric ... with unregistered descriptor` until `systemctl restart prometheus-smartctl-exporter`. Fixed upstream in v0.15.0 (prometheus-community/smartctl_exporter#329).

**Common PromQL patterns:**
```promql
# Disk temperature (watch for > 50°C on NAS drives)
smartctl_device_temperature{instance="glyph"}

# PostgreSQL active connections per database
pg_stat_database_numbackends{instance="glyph"}

# nginx request rate over 5 minutes
rate(nginx_http_requests_total{instance="spore"}[5m])

# Filesystem use % on glyph (watch for > 85%)
100 - (node_filesystem_avail_bytes{instance="glyph",mountpoint="/"} / node_filesystem_size_bytes{instance="glyph",mountpoint="/"} * 100)
```

### Blind spots

Know these before concluding "no data means no problem":
- Grafana and its PostgreSQL database run on glyph. If glyph is down, Grafana and all Grafana alerting go down with it; Gatus on zeta still alerts. If spore is down, `grafana.zx.dev` is unreachable but alerting keeps running.
- Per-vhost HTTP status and latency exist only as LogQL over `app="nginx_access"`, not as Prometheus metrics. The `nginx` job is `stub_status` connection counts.
- Local `just switch` prints switch-to-configuration output (units restarted, failed units) to the terminal only. Loki gets the `nixos-deploy` line, and systemd logs each unit start, stop and failure as usual.
- Deploy workflow output is written to the journal after the deploy finishes, so its lines are timestamped at the end of the run. It leaves out the `copying path` lines and store path lists. If the host is unreachable, the output exists only in GitHub Actions.
- No metrics for Alloy, Grafana, or individual app internals (Jellyfin, Home Assistant, Windmill, etc.). Use `node_systemd_unit_state` and Loki.

## Guardrails

- Merging doesn't deploy: deploys are manual, via `just switch` or the Deploy workflow. Don't switch a host, merge a PR, or run the Deploy workflow unless asked.

## Committing

- My git config requires signing, which you can't do (it needs an interactive GPG unlock). For commands that create commits, use `git -c commit.gpgsign=false …`, and never change git config to disable signing. Add a `Co-Authored-By:` trailer identifying yourself.

## Updating this file

- When a working solution reached through trial and error would help future sessions in this repo, add it to this file in the PR you're preparing and call it out in the PR description.

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`.

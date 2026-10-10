# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

A Nix flake that configures every host:

- **NixOS**: `zeta` (ARM/Pi4), `glyph` (x86_64 NAS/homelab), `spore` (x86_64 VPS)
- **macOS (nix-darwin)**: `Rhizome` (personal laptop), `Stroma` (Mac Studio), `lobtop` (work laptop)

Layout:
- `hosts/<host>/`: per-host configuration
- `modules/`: shared modules: `base/` (all hosts: nix settings, GC, unfree packages), `nixos/`, `darwin/`, `home/` (home-manager modules)
- `home/`: the home-manager configuration every host imports
- `lib/hosts.nix`: host builders (`mkNixosHost`, `mkDarwinHost`); `lib/keys.nix`, `lib/secrets/`: SSH keys and agenix recipients
- `overlays/`: package overrides, listed in `overlays/default.nix` with a comment saying why each exists
- `packages/<name>/package.nix`: packages not in nixpkgs, exposed by `overlays/custom-packages.nix`

## Common Commands

**Build and switch to configuration** (only when asked; see Guardrails):
```bash
just                              # Switch current host
just switch hostname              # Switch specific host
just switch-remote spore          # Build on this host, deploy to spore (it's memory-constrained)
```

**Check a change before committing** (evaluates without building; catches option conflicts and type errors):
```bash
nix-flake eval nixosConfigurations.<host>.config.system.build.toplevel.drvPath   # NixOS
nix-flake eval darwinConfigurations.<host>.system.drvPath                       # macOS
```

**Flake inputs:** `nix flake update --commit-lock-file`. The Update workflow does this daily and auto-merges once CI passes.

**Dev shell:** `nix develop` provides agenix and just. Claude Code sessions in Zed don't run inside it; prefix devShell tools with `direnv exec .`, e.g. `direnv exec . agenix -e hosts/spore/secrets/foo.age`.

## Key Configuration Details

- Usernames: `mu` on Linux, `corey` on macOS
- SSH key authentication everywhere; keys in `lib/keys.nix`, each host's read from `hosts/<host>/key.pub`
- macOS hosts use nix-homebrew with taps pinned as flake inputs (`mutableTaps = false` in `lib/hosts.nix`)

## Secrets

agenix, least privilege: each host decrypts only its own secrets plus the admin keys. Recipients are listed per host in `lib/secrets/<host>.nix` (shared ones in `lib/secrets/default.nix`).

```bash
agenix -e hosts/spore/secrets/some-secret.age   # edit (needs a key that can decrypt it)
agenix --rekey                                  # after adding a host key
```
To add a secret: add its entry to `lib/secrets/<host>.nix`, create it with `agenix -e hosts/<host>/secrets/<name>.age`, and reference it with `age.secrets.<name>.file`. A new host needs its key in `lib/keys.nix` and in the relevant secrets entries before it can decrypt anything.

## Branching

- Scope branches to a single host whenever possible. This keeps deploys independent and reduces the risk of cross-host breakage.
- Branch naming: `scope/type-short-slug`, where scope is the hostname (`glyph`, `spore`, `zeta`, `Rhizome`, `Stroma`, `lobtop`) or `home` for shared home-manager changes. Top-level or cross-cutting changes drop the scope: `type-short-slug`.
  - `type` is one of `feat`, `fix`, `chore`, `refactor`; the slug is 2 to 4 words.
  - Examples: `spore/fix-gc-options`, `home/feat-claude-memory`, `chore-update-flake-inputs`.
- PR title: `type(scope): short description`, with the scope omitted for top-level changes, e.g. `fix(spore): gc options`, `chore: update flake inputs`. PRs are squash-merged, so the title becomes the commit message.
- PR description: a brief summary of what changed and what to test or verify.

## Sandboxed sessions

If `nix-flake` isn't on PATH, you're in a sandboxed session without my tooling, and Nix may not be installed. Don't try to evaluate or build. Make the change, push the branch, and open a PR: CI evaluates and builds every host.

## Common Patterns

**`lib.mkForce` vs `lib.mkDefault`:** a host that must diverge from a value a shared module sets uses `lib.mkForce`; without it Nix errors on the conflicting definitions. A shared module that wants hosts to override freely sets `lib.mkDefault` instead. Example: `modules/base/gc.nix` sets `nix.gc.dates = "weekly"`, and `hosts/spore/default.nix` overrides it with `lib.mkForce "daily"`.

## Monitoring Stack

Grafana, Loki and Prometheus on glyph. Use them before `journalctl` or SSH when investigating failures, slowness or disk issues.

- **Grafana** (glyph:3000, `grafana.zx.dev` via spore): config in `hosts/glyph/services/grafana.nix`; the image renderer (localhost:8081) backs `get_panel_image`.
- **Loki** (glyph:3100): journald from glyph, spore and zeta via Alloy, plus Claude Code events over OTLP; 30 days.
- **Prometheus** (glyph:9099): scrapes glyph, spore, zeta and Stroma (`hosts/Stroma/monitoring.nix`), plus OTLP pushes; 90 days.
- **Alert rules**: `hosts/glyph/services/grafana-alerts.nix` (folder "Alerts", routed to Slack). Add rules there, not in the UI.
- **Dashboards**: JSON in `hosts/glyph/services/dashboards/`: Node, ZFS, Log Explorer, PostgreSQL, Disk Health (SMART), Systemd Units, nginx, Apple Silicon (Stroma).
- **Gatus** (zeta:8080, `status.zx.dev`): out-of-band watchdog in `hosts/zeta/services/gatus.nix` that posts to Slack itself, so it alerts when glyph or Grafana is down. Every minute it checks glyph (reachability, Postgres, Prometheus freshness, Loki ingestion, Grafana through spore), spore, and the public sites through their `*.zx.dev` URLs; the `zx.dev` cert hourly.

**grafana-mcp:** registered in mcpjungle on glyph (`http://127.0.0.1:8095/mcp`) with LogQL, PromQL and dashboard tools. It's read-only (`--disable-write` in `modules/nixos/llm/grafana-mcp.nix`): change alert rules and dashboards in the flake.

**MCPJungle** serves the tool list it fetched when each server registered. `mcpjungle-register` re-registers every server at boot and when a local server's unit changes (`restartTriggers` in `hosts/glyph/services/default.nix`); by hand: `systemctl restart mcpjungle-register`. Re-registering deregisters first, so a server that fails loses its tools and the unit exits non-zero (the "Systemd unit failed" alert fires); `{unit="mcpjungle-register.service"} |= "ERROR"` names it. Servers needing auth take `headers` plus an `environmentFile`.

**Grafana exits with "Using the default [rendering]renderer_token is not allowed":** Grafana 13 rejects the default token whenever an image renderer is configured. `grafana.nix` sets the same `rendererToken` on both sides; keep them in sync.

### Loki label schema

Journald streams carry these labels:

| Label | Source journal field | Example values |
|---|---|---|
| `host` | Static (Alloy external_labels) | `glyph`, `spore`, `zeta` |
| `unit` | `_SYSTEMD_UNIT` | `navidrome.service`, `nginx.service` |
| `priority` | `PRIORITY` | `0`–`7` (0=emerg, 3=err, 4=warn, 6=info, 7=debug) |
| `app` | `SYSLOG_IDENTIFIER` | `navidrome`, `nginx`, `kernel` |

**Alloy journal relabel names:** the source label is `__journal_` plus the lowercased field name, so `_SYSTEMD_UNIT` becomes `__journal__systemd_unit` (double underscore) and `PRIORITY` becomes `__journal_priority`.

**Alloy active but shipping nothing:** if `loki_source_journal_target_lines_total` (`curl -s localhost:12345/metrics`) stays at 0 while `journalctl` works, alloy's libsystemd can't read the zstd-compressed journal. nixpkgs links it against `systemdLibs`, built without zstd; `overlays/grafana-alloy.nix` relinks it against full systemd. Deleting alloy's saved positions doesn't help.

```logql
{host="glyph", unit="navidrome.service", priority=~"[0-3]"}   # errors and above from one service
{host="spore", app="nginx"}                                    # nginx error log
# nginx access log is JSON: vhost, method, uri, status, bytes, request_time,
# upstream_time, upstream_status, remote_addr, user_agent
{host="spore", app="nginx_access"} | json | status >= 500
quantile_over_time(0.95, {host="spore", app="nginx_access"} | json | unwrap request_time [5m]) by (vhost)
```

To summarise a noisy stream, use grafana-mcp's `query_loki_patterns` (e.g. `{host="glyph", unit="jellyfin.service"}`). Patterns live in Loki's memory, so they only cover logs since Loki last restarted.

### Deploys

Check deploys first when something regressed. Dashboards show them as a purple "Deploys" annotation. On a host, `nixos-version --configuration-revision` gives the deployed revision.

```logql
# One marker per activation, whichever path ran it: action (switch/test; nh
# logs test), flake revision ("<rev>-dirty" for local builds), store path
{app="nixos-deploy", priority="5"}
# The nvd package diff that follows each marker ("[U.] #3 grafana 12.1.0 -> 12.2.0")
{host="glyph", app="nixos-deploy", priority="6"}
# Deploy workflow's deploy-rs output; last line is the summary with the run URL
# (priority err on failure)
{host="spore", app="deploy-rs"}
# switch-to-configuration output, only for `just switch-remote`
{unit="nixos-rebuild-switch-to-configuration.service"}
```

### Claude Code telemetry

Hosts with `rc.development.ai.telemetry.enable` (default: those that reach the gateway, so not lobtop) push Claude Code metrics to Prometheus and events to Loki over OTLP (env in `modules/home/development.nix`). Prompt, response and tool-input text are redacted at the source. Labels include `host` (lowercase hostname), `session_id`, `model` and `user_email`. Metrics export every 60s, so a session's series appear about a minute after its first request.

The terminal CLI reports `service_name`/`job` `claude-code` with `host`. The desktop app's built-in Claude Code reports `claude-code-desktop` and drops `host`; match both with `=~"claude-code.*"`. A desktop session's `user_id` (per-machine install ID) equals that machine's CLI `user_id`.

```promql
# Spend and tokens per host and model over the last day
sum by (job, host, model) (increase(claude_code_cost_usage_USD_total{job=~"claude-code.*"}[1d]))
sum by (type) (increase(claude_code_token_usage_tokens_total{job=~"claude-code.*"}[1d]))
```
Also `claude_code_{session,lines_of_code,commit,pull_request}_count_total` and `claude_code_active_time_seconds_total`, each once it first happens.

```logql
# Events: one line per event ("claude_code.api_request"); fields are
# structured metadata (event_name, tool_name, success, duration_ms,
# cost_usd, ttft_ms, input_tokens, ...)
{service_name="claude-code", host="rhizome"} | event_name="api_error"
{service_name=~"claude-code.*"} | event_name="tool_result" | success="false"
```

### Prometheus jobs and exporters

Scraped series carry `instance` and an identical `host` label, so `{host="glyph"}` selects the same machine in PromQL and LogQL. Pushed (OTLP) series don't: Open WebUI's have `instance` only; Claude Code's are above.

| Job | Port | Host | Covers |
|---|---|---|---|
| `node` | 9100 | glyph, spore, zeta, stroma | CPU, memory, disk, network, systemd unit states, restarts (`node_systemd_service_restart_total`), start times, timer last-trigger. Stroma is macOS: no systemd series and no `node_memory_MemAvailable_bytes` |
| `mactop` | 9101 | stroma | Apple Silicon: `mactop_cpu_usage_percent` (and `mactop_{e,p,s}core_usage_percent`; M5 has P- and S-cores, no E-cores), `mactop_gpu_usage_percent`, `mactop_power_watts{component}` (cpu, gpu, ane, dram, gpu_sram, system, total: total is whole-machine power and system is the remainder, so the others sum to total; on M5 these need mactop 2.1.6+, see `overlays/mactop.nix`), `mactop_dram_bandwidth_gbs` (0 on M5 Ultra), `mactop_soc_temp_celsius`, `mactop_thermal_state` (0–3), `mactop_memory_gb{type}`, fans |
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
| `grafana` | 3000 | glyph | Grafana itself: `grafana_alerting_rule_evaluation_failures_total`, notification and HTTP metrics |
| `alloy` | 12345 | glyph, spore, zeta | Alloy itself: `loki_write_sent_entries_total`, `loki_write_dropped_entries_total`, journal read counters |
| `mcpjungle` | 8090 | glyph | MCP gateway tool calls: `mcpjungle_tool_calls_ratio_total{mcp_server_name, tool_name, outcome}` and `mcpjungle_tool_call_latency_seconds`. `outcome="error"` means the gateway couldn't reach or talk to the upstream server, not a tool's own error result. The `_ratio` comes from the OTel unit `"1"`; series appear after a tool's first call |
| `open-webui` | push (OTLP) | glyph | `http_server_requests_total`, `http_server_duration_*`, `webui_users_*`; pushed to Prometheus's OTLP receiver, not scraped, so no `up` series |

**Picking a port on glyph:** grep the repo and check defaults that aren't declared in Nix. Transmission's RPC takes 9091 (`torrents.zx.dev`), so an exporter there fails with "address already in use".

**smartctl exporter fails every scrape with `collected metric ... with unregistered descriptor`:** v0.14.0 registers metrics only for disks readable at startup, so a disk that becomes readable later (NVMe ACL, drive waking) breaks it until `systemctl restart prometheus-smartctl-exporter`. Fixed in v0.15.0 (prometheus-community/smartctl_exporter#329).

### Blind spots

Know these before concluding "no data means no problem":
- Grafana and its database run on glyph: if glyph is down, all Grafana alerting is down too (Gatus still alerts). If spore is down, `grafana.zx.dev` is unreachable but alerting keeps running.
- Per-vhost HTTP status and latency exist only as LogQL over `app="nginx_access"`; the `nginx` job is `stub_status` connection counts.
- Local `just switch` prints switch-to-configuration output only to the terminal; Loki gets the `nixos-deploy` lines and systemd's own unit logs.
- Deploy workflow output lands in the journal after the deploy finishes (timestamped at the end, without `copying path` lines), and only in GitHub Actions if the host was unreachable.
- No metrics for app internals (Jellyfin, Home Assistant, etc.): use `node_systemd_unit_state` and Loki.
- macOS hosts ship no system logs to Loki (only Claude Code events).

## Guardrails

- Merging doesn't deploy: deploys are manual, via `just switch` or the Deploy workflow. Don't switch a host, merge a PR, or run the Deploy workflow unless asked.

## Committing

- My git config requires signing, which you can't do (it needs an interactive GPG unlock). For commands that create commits, use `git -c commit.gpgsign=false …`, and never change git config to disable signing. Add a `Co-Authored-By:` trailer identifying yourself.

## Updating this file

- When a working solution reached through trial and error would help future sessions in this repo, add it to this file in the PR you're preparing and call it out in the PR description.

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`.

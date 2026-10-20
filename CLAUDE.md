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
- SSH key authentication everywhere; keys in `lib/keys.nix`. `keys.<host>` is the host's sshd host key from `hosts/<host>/key.pub` (agenix recipient, deploy known_hosts), never a login key.
- People log in only with the YubiKeys or, from Rhizome and Stroma, a Secure Enclave key (`keys.secureEnclave`, `hosts/<host>/secretive.pub`: Secretive, Touch ID on every use, offered first through Secretive's agent; plain ecdsa, so unlike `verify-required` sshd can't check the Touch ID). The YubiKeys: `keys.yubikeys` (`lib/admin/ssh-yubikey-{a,b}.pub`, FIDO2 `ed25519-sk`), listed with `verify-required`, so every login needs the FIDO2 PIN and a touch. That's mu's and root's `authorized_keys` on the NixOS hosts and the user's on Stroma. The Macs use nixpkgs' OpenSSH (Apple's client can't use security keys) with `IdentityAgent none` for the servers. Their key handles (`ssh-keygen -K` output; not secret, useless without the YubiKey) are committed as `lib/admin/ssh-yubikey-{a,b}`, and home-manager copies them to `~/.ssh/id_ed25519_sk_rc_{a,b}` with mode 0600 (ssh rejects the 0444 store files), so a Mac needs no setup. A replacement YubiKey means new handles and `.pub` files there. SSH to the servers from the Macs shares connections (`ControlMaster auto`, `ControlPersist 10m`), so one PIN and touch covers a host until 10 minutes after its last session; `ssh -O exit <host>` closes it. ykding (`programs.ykding`, pinned in `packages/ykding`, not the Homebrew tap) dings and shows a banner naming who is asking whenever a YubiKey waits for a touch. nixpkgs' `ssh` gets "No route to host" to LAN IPs (macOS Local Network privacy), so use tailnet names.
- Unattended SSH is root only: `keys.deploy` (CI) everywhere, and `keys.clients.glyph` on spore and zeta (`hosts/glyph/client.pub`; private key is glyph's agenix secret `ssh-client-key`, used by mu's SSH config on glyph). Nothing logs into glyph unattended. Tailscale SSH is off (`extraSetFlags = ["--ssh=false"]` on glyph and zeta), so port 22 on tailnet addresses reaches sshd
- Tailnet Lock is on, with Rhizome and Stroma as the signing nodes (the Mac app's CLI: `/Applications/Tailscale.app/Contents/MacOS/Tailscale lock ...` unless `tailscale` is on PATH). A new device, or one whose Tailscale state was wiped, shows "Locked out" until a signing node runs the `tailscale lock sign nodekey:... tlpub:...` command from its Machines entry (or from `tailscale lock status` on the new device). Logging back in after key expiry re-signs itself. Disabling the lock needs one of the 10 disablement secrets, in the password manager; without them, `tailscale lock local-disable` on every node is the last resort.
- Deploy workflow runners join the tailnet with `TS_AUTHKEY`, a reusable, ephemeral `tag:ci` auth key signed on a signing node (OAuth clients can't join a locked tailnet). Signing it adds a new trusted signing key to the lock (`(pre-auth key <id>)` in `tailscale lock status`) whose private half is inside `TS_AUTHKEY`, so the secret can sign any node, not just CI runners, and that key stays trusted after the auth key expires. It expires within 90 days and zeta's `tailscale-key-expiry` warns 14 days ahead. To replace it: create the key in the admin console (Settings > Keys: reusable, ephemeral, tag `tag:ci`, 90 days), run `tailscale lock sign <key>` on Rhizome or Stroma, store the printed key as the `TS_AUTHKEY` repo secret, run one Deploy, then revoke the old auth key and remove its signing key with `tailscale lock remove --re-sign=false tlpub:...` (the old `(pre-auth key ...)` line).
- macOS hosts use nix-homebrew with taps pinned as flake inputs (`mutableTaps = false` in `lib/hosts.nix`)

## Secrets

agenix, least privilege: each host decrypts only its own secrets. The admin recipients are two YubiKeys (`keys.admins` in `lib/keys.nix`; age-plugin-yubikey, PIV slot 1): `a` for daily use, `b` an offline spare. Their identity files in `lib/admin/` only point at the YubiKey slot and aren't secret. Host rules are built by `lib/secrets/mk-host.nix` (`import ./mk-host.nix "<host>" ["<name>" ...]` gives `hosts/<host>/secrets/<name>.age` the host's key plus `keys.admins`); secrets shared by several hosts are written out in `lib/secrets/default.nix` (system; currently none) and `home.nix` (user). restic (`rc.backup`, glyph only) reads `hosts/<host>/secrets/restic-{env,password}.age`: a host that starts backing up needs its own R2 bucket and bucket-scoped token, since R2 tokens can't be limited to a prefix.

```bash
agenix -e hosts/spore/secrets/some-secret.age -i lib/admin/yubikey-a.txt   # edit: PIV PIN, then touch
agenix -r -i lib/admin/yubikey-a.txt                                       # re-encrypt after changing recipients
```
Creating a secret, or replacing one from stdin (`echo -n value | agenix -e ...`), only encrypts and needs no YubiKey. The devShell puts `age-plugin-yubikey` on PATH, which agenix's `age` needs to use YubiKey recipients and identities. `agenix -c` can't check age-plugin recipients and fails on every file, so don't rely on it.

Every host, macOS included, decrypts with one identity: sshd's host key (`/etc/ssh/ssh_host_ed25519_key`, which `hosts/<host>/key.pub` holds; on a Mac, `sudo ssh-keygen -A` creates it). On macOS agenix's darwin module decrypts at boot, before login. There's no home-manager agenix: a user's secret is a system secret with `owner = username`, declared in the host's config, and home-manager reads its path from `osConfig.age.secrets.<name>.path`. aichat is only installed on hosts that declare `aichat-env`.

To add a secret: add its name to the host's list in `lib/secrets/<host>.nix`, create it with `agenix -e hosts/<host>/secrets/<name>.age`, and reference it with `age.secrets.<name>.file`. A new host needs `hosts/<host>/key.pub`, an entry in `lib/keys.nix`, and a `lib/secrets/<host>.nix` imported by `lib/secrets.nix` before it can decrypt anything.

## Branching

- Scope branches to a single host whenever possible. This keeps deploys independent and reduces the risk of cross-host breakage.
- Branch naming: `scope/type-short-slug`, where scope is the hostname (`glyph`, `spore`, `zeta`, `Rhizome`, `Stroma`, `lobtop`) or `home` for shared home-manager changes. Top-level or cross-cutting changes drop the scope: `type-short-slug`.
  - `type` is one of `feat`, `fix`, `chore`, `refactor`; the slug is 2 to 4 words.
  - Examples: `spore/fix-gc-options`, `home/feat-claude-memory`, `chore-update-flake-inputs`.
- In cloud sessions, name branches with the repo's scheme, even when the session assigns a `claude/…` branch name: `<host>/type-short-slug` for a change to one host (`glyph/fix-gc-options`), and `type-short-slug` with no scope for changes to several hosts or none (`chore-cloud-branch-naming`).
- PR title: `type(scope): short description`, with the scope omitted for top-level changes, e.g. `fix(spore): gc options`, `chore: update flake inputs`. PRs are squash-merged, so the title becomes the commit message.
- PR description: a brief summary of what changed and what to test or verify.

## Sandboxed sessions

If `nix-flake` isn't on PATH, you're in a sandboxed session without my tooling, and Nix may not be installed. Don't try to evaluate or build. Make the change, push the branch, and open a PR: CI evaluates and builds every host.

If `nix` is installed, run `scripts/fmt-sandboxed` instead of `nix fmt .`. Cloud sessions can't download GitHub tarballs (`github:` inputs fail with HTTP 403) but can `git clone` public repos, so the script overrides the formatter's inputs with shallow git fetches of the locked revs. Shallow matters: a full nixpkgs clone takes far too long. Evaluating hosts would need the same override for most inputs, so leave that to CI.

## Common Patterns

**launchd daemons on macOS hosts:** set `launchd.daemons.<name>.command`, not `serviceConfig.ProgramArguments`, when the program is in `/nix/store`. nix-darwin wraps `command` in `/bin/wait4path /nix/store`; with ProgramArguments, launchd starts the daemon at boot before the Nix volume is mounted, and it stays down until the next switch (Stroma's alloy, mactop and json-exporter were down for three days after a reboot). Programs outside the store, like oMLX from Homebrew, are fine either way.

**`lib.mkForce` vs `lib.mkDefault`:** a host that must diverge from a value a shared module sets uses `lib.mkForce`; without it Nix errors on the conflicting definitions. A shared module that wants hosts to override freely sets `lib.mkDefault` instead. Example: `modules/base/gc.nix` sets `nix.gc.dates = "weekly"`, and `hosts/spore/default.nix` overrides it with `lib.mkForce "daily"`.

## Monitoring Stack

Grafana, Loki and Prometheus on glyph. Use them before `journalctl` or SSH when investigating failures, slowness or disk issues.

- **Grafana** (glyph:3000, `monitoring.zx.dev` via spore): config in `hosts/glyph/services/grafana.nix`; the image renderer (localhost:8081) backs `get_panel_image`.
- **Loki** (glyph:3100): journald from glyph, spore and zeta via Alloy, oMLX's log from Stroma, plus Claude Code events over OTLP; 30 days.
- **Prometheus** (glyph:9099): scrapes glyph, spore, zeta and Stroma (node_exporter, mactop, json_exporter for oMLX, Alloy; `hosts/Stroma/monitoring.nix`), plus OTLP pushes; 90 days.
- **CI failures**: the `notify` job in `.github/workflows/ci.yml` posts to #alerts as Hypha through `stackptr/actions/slack-notify` (pinned by SHA; needs the `SLACK_BOT_TOKEN` repo secret and `permissions: actions: read`). Test a change to it with `dry-run: true`.
- **Alert rules**: `hosts/glyph/services/grafana-alerts.nix` (folder "Alerts", routed to Slack). Add rules there, not in the UI.
- **Dashboards**: JSON in `hosts/glyph/services/dashboards/`: Node, ZFS, Log Explorer, PostgreSQL, Disk Health (SMART), Systemd Units, nginx, Apple Silicon (Stroma).
- **Gatus** (zeta:8080, `status.zx.dev`): out-of-band watchdog in `hosts/zeta/services/gatus.nix` that posts to Slack itself, so it alerts when glyph or Grafana is down. Every minute it checks glyph (reachability, Postgres, Prometheus freshness, Loki ingestion, Grafana through spore), spore, and the public sites through their `*.zx.dev` URLs; the `zx.dev` cert hourly. Hourly, `tailscale-key-expiry.service` asks the Tailscale API (OAuth client in `gatus-env.age`) for node keys expiring within 14 days or servers with expiry enabled, and pushes the result to Gatus's `tailscale/key-expiry` endpoint, which also fires if no result arrives for 3h.

**Slack:** everything posts as the Hypha bot, one token (`slack-bot-token.age` on glyph, `SLACK_BOT_TOKEN` in zeta's `gatus-env.age`). Alerts (Grafana, Gatus) go to #alerts; informational posts (downloads) go to #updates. CI failures still post to #updates through an incoming webhook until they move to the shared action in `stackptr/actions`. The top-level `text` is the notification preview, so every message needs one: a message with only attachments notifies as "[no preview available]". A service on any host sends a notification by publishing to ntfy on glyph (`http://glyph:2586/notifications`, JSON publish built with `jq`): `title` is the preview, `message` is Slack mrkdwn, the first tag is the emoji, `click` is a link, and priority 4 or higher goes to #alerts (`hosts/glyph/services/ntfy-to-slack.jq`).

**grafana-mcp:** registered in mcpjungle on glyph (`http://127.0.0.1:8095/mcp`) with LogQL, PromQL and dashboard tools. It's read-only (`--disable-write` in `modules/nixos/llm/grafana-mcp.nix`): change alert rules and dashboards in the flake.

**MCPJungle** serves the tool list it fetched when each server registered. `mcpjungle-register` re-registers every server at boot and when a local server's unit changes (`restartTriggers` in `hosts/glyph/services/default.nix`); by hand: `systemctl restart mcpjungle-register`. Re-registering deregisters first, so a server that fails loses its tools and the unit exits non-zero (the "Systemd unit failed" alert fires); `{unit="mcpjungle-register.service"} |= "ERROR"` names it. Servers needing auth take `headers` plus an `environmentFile`.

Registration is authoritative: the unit also deregisters any server not in `services.mcpjungle.servers` (so don't register one by hand), re-applies each server's `disabledTools`, and then recreates the tool groups in `services.mcpjungle.groups`, each served at `/v0/groups/<name>/mcp` (Open WebUI uses `chat`). Groups are deleted and recreated, not updated: while servers re-sync in parallel, MCPJungle can leave a re-added tool out of a group's endpoint even though `GET /api/v0/tool-groups/<name>/effective-tools` lists it, and `update group` with an unchanged config doesn't repair it. A group that includes a disabled tool can't be created, so the module adds every `disabledTools` entry to each group's `excluded_tools`.

**Grafana exits with "Using the default [rendering]renderer_token is not allowed":** Grafana 13 rejects the default token whenever an image renderer is configured. `grafana.nix` sets the same `rendererToken` on both sides; keep them in sync.

### Loki label schema

Journald streams carry these labels:

| Label | Source journal field | Example values |
|---|---|---|
| `host` | Static (Alloy external_labels) | `glyph`, `spore`, `zeta` |
| `unit` | `_SYSTEMD_UNIT` | `navidrome.service`, `nginx.service` |
| `priority` | `PRIORITY` | `0`–`7` (0=emerg, 3=err, 4=warn, 6=info, 7=debug) |
| `app` | `SYSLOG_IDENTIFIER` | `navidrome`, `nginx`, `kernel` |

**Podman containers log everything at `priority="3"`:** oci-containers units (`podman-<name>.service` on glyph: audiomuse-flask, audiomuse-worker, open-terminal) write the containers' stderr to the journal at err, INFO lines included, so `priority=~"[0-3]"` matches everything. Filter on the text instead, e.g. `|~ "\\[(ERROR|CRITICAL|WARNING)\\]|Traceback"`.

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

**oMLX** (local LLM server on Stroma, `hosts/Stroma/omlx.nix`) logs to `~/.omlx/logs/server.log`, which Alloy on Stroma ships as `{host="stroma", app="omlx"}`. Its Python log levels map to the journald `priority` numbers (ERROR 3, WARNING 4, INFO 6), and tracebacks stay in one entry. Each completed request logs one line, the source for recent per-request speed:
```logql
# "Chat completion: model=X, 412 tokens in 6.31s (65.3 tok/s), ..., stream_model_ttft=0.48s"
avg_over_time({host="stroma", app="omlx"} |~ " tokens in .* tok/s" | regexp `model=(?P<model>[^,]+), \d+ tokens in [\d.]+s \((?P<tps>[\d.]+) tok/s` | unwrap tps [5m]) by (model)
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
| `node` | 9100 | glyph, spore, zeta, stroma | CPU, memory, disk, network, systemd unit states, restarts (`node_systemd_service_restart_total`, which counts only systemd's own `Restart=` restarts; catch a stop/start or a recreated container with `time() - node_systemd_unit_start_time_seconds`), start times, timer last-trigger. Stroma is macOS: no systemd series and no `node_memory_MemAvailable_bytes` |
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
| `alloy` | 12345 | glyph, spore, zeta, stroma | Alloy itself: `loki_write_sent_entries_total`, `loki_write_dropped_entries_total`, journal read counters |
| `mcpjungle` | 8090 | glyph | MCP gateway tool calls: `mcpjungle_tool_calls_ratio_total{mcp_server_name, tool_name, outcome}` and `mcpjungle_tool_call_latency_seconds`. `outcome="error"` means the gateway couldn't reach or talk to the upstream server, not a tool's own error result. The `_ratio` comes from the OTel unit `"1"`; series appear after a tool's first call |
| `omlx` | 7979/probe | stroma | oMLX via json_exporter, which fetches `http://127.0.0.1:8000/api/status` per scrape with the oMLX sub-key from agenix (`omlx-monitoring-key.age`; a missing or rejected key makes `up` 0): `omlx_requests_{active,waiting}`, `omlx_{requests,prompt_tokens,completion_tokens,cached_tokens}_total`, `omlx_models_{loaded,loading,discovered}`, `omlx_loaded_model_info{model}`, `omlx_model_memory_used_bytes`, `omlx_avg_{prefill,generation}_tokens_per_second`, `omlx_cache_efficiency_percent`, `omlx_info{version}`. Counters reset when oMLX restarts and the averages run from its start; `up == 0` means oMLX isn't answering |
| `open-webui` | push (OTLP) | glyph | `http_server_requests_total`, `http_server_duration_*`, `webui_users_*`; pushed to Prometheus's OTLP receiver, not scraped, so no `up` series |

**A rule that never fires:** Grafana's threshold step (C) tests each series' value, by default `> 0`, so a PromQL filter that leaves zeros (`up == 0`, `x != 1` on a 0/1 gauge) matches series but stays Normal. Query the raw value and set `evaluator` in `mkRule` instead (`grafana-alerts.nix`).

**Picking a port on glyph:** grep the repo and check defaults that aren't declared in Nix. Transmission's RPC takes 9091 (`torrents.zx.dev`), so an exporter there fails with "address already in use".

**smartctl exporter fails every scrape with `collected metric ... with unregistered descriptor`:** v0.14.0 registers metrics only for disks readable at startup, so a disk that becomes readable later (NVMe ACL, drive waking) breaks it until `systemctl restart prometheus-smartctl-exporter`. Fixed in v0.15.0 (prometheus-community/smartctl_exporter#329).

**`home.zx.dev` returns "400: Bad Request"** (Home Assistant on zeta): since HA 2026.8 the HTTP server settings live in the UI, not `configuration.yaml`. YAML `http:` is imported once, then ignored, so editing it in Nix does nothing. If the import is rolled back (an admin must confirm the new settings within 5 minutes, impossible while logins are broken), HA falls back to defaults and rejects spore's proxy: `{host="zeta", unit="home-assistant.service"} |= "untrusted proxy"` shows `Received X-Forwarded-For header from an untrusted proxy <spore's tailnet IP>`. Fix: open `http://zeta.note-iwato.ts.net:8123` directly (not through spore), then Settings > System > Network > HTTP server: turn on Trust X-Forwarded-For, add `100.64.0.0/10` to Trusted proxies, save, log back in after the restart and confirm within 5 minutes. The Gatus `sites/home-assistant` check expects 401 from `https://home.zx.dev/api/` and fires on a 400.

**AudioMuse-AI** (glyph:8001, `mix.zx.dev` via spore behind Pocket ID; `hosts/glyph/services/audiomuse.nix`): the upstream image as podman containers (flask, and three workers `audiomuse-worker{,-2,-3}` at `--cpus=7 --cpu-shares=256` each, since one worker runs one album job at a time) on glyph's Postgres (database `audiomuse`, over `/run/postgresql`). Only infrastructure is in Nix. At first start it copies every setting, environment ones included, into its `app_config` table, which then overrides the environment: changing an env var in Nix does nothing on an existing database. Change settings in its UI, or for ones the UI doesn't show (like `ENABLE_PROXY_FIX`) `UPDATE app_config SET value = 'true' WHERE key = '...'` and restart both units. With a single uncapped worker the first analysis ran at about 10 tracks/min on a third to half of glyph's 24 cores; AudioMuse sizes its thread pools from the cgroup quota, so `--cpus` sets each worker's threads too. Progress: `audiomuse_tracks_analysed` (a 5-minute timer counts the `score` table into node_exporter's textfile collector) against Navidrome's `db_model_totals{model="media"}`; both are on Homepage. Its own auth is off (Setup Wizard toggle), so `mix.zx.dev`'s Pocket ID is the only gate and anything on the tailnet can use glyph:8001; Navidrome's plugin still sends the API token, ignored while auth is off. If auth is turned back on and admin access is lost: delete the `AUDIOMUSE_USER`/`AUDIOMUSE_PASSWORD` rows from `app_config` and the admin rows from `audiomuse_users`, restart both units, and the Setup Wizard returns. The image tag is pinned; bump it by hand. Gatus's `glyph/audiomuse` checks flask's `/api/health`. A crashing container is caught by the "Systemd unit restart loop" alert, but supervisord inside each container restarts its own processes, so a worker process that crash-loops never reaches systemd: look in Loki.

**Navidrome rebuilds whenever its plugins change:** `services.navidrome.plugins` overrides the `navidrome` package itself (its `postInstall` links the `.ndp` files), so the plugin list is an input to the full Go and web UI build and cache.nixos.org never has it. CI builds it into attic; if the CI run for a commit was cancelled, switching glyph compiles Navidrome locally.

### Blind spots

Know these before concluding "no data means no problem":
- Grafana and its database run on glyph: if glyph is down, all Grafana alerting is down too (Gatus still alerts). If spore is down, `monitoring.zx.dev` is unreachable but alerting keeps running.
- Per-vhost HTTP status and latency exist only as LogQL over `app="nginx_access"`; the `nginx` job is `stub_status` connection counts.
- Local `just switch` prints switch-to-configuration output only to the terminal; Loki gets the `nixos-deploy` lines and systemd's own unit logs.
- Deploy workflow output lands in the journal after the deploy finishes (timestamped at the end, without `copying path` lines), and only in GitHub Actions if the host was unreachable.
- No metrics for app internals (Jellyfin, Home Assistant, etc.): use `node_systemd_unit_state` and Loki.
- macOS hosts ship no system logs to Loki, only Claude Code events and (from Stroma) oMLX's log.

### Tailnet lockout

Tailscale logs in through Pocket ID (`id.zx.dev`, on spore), whose database is on glyph over the tailnet. If glyph's or spore's node key expires, `id.zx.dev` returns 502 (and `cache.zx.dev` 504), so no device can log back in. Break the cycle with a reverse SSH tunnel to glyph's Postgres (`pg_hba` trusts loopback) over spore's public IP:
```bash
ssh -i /run/agenix/ssh-client-key -N -R 127.0.0.1:5432:127.0.0.1:5432 root@<spore-public-ip>    # on glyph as mu; keep it running
# on spore (runtime only; gone on reboot):
mkdir -p /run/systemd/system/pocket-id.service.d
echo 'DB_CONNECTION_STRING=postgres://pocketid@127.0.0.1/pocketid' > /run/pocket-id-override.env
printf '[Service]\nEnvironment=DB_CONNECTION_STRING=postgres://pocketid@127.0.0.1/pocketid\nEnvironmentFile=/run/pocket-id-override.env\n' > /run/systemd/system/pocket-id.service.d/tunnel.conf
systemctl daemon-reload && systemctl restart pocket-id    # the stop can take its 90s timeout
```
Then log the expired machines back in (Tailnet Lock re-signs them; nothing needs signing unless a machine lost its Tailscale state) and disable their key expiry in the admin console, check `tailscale ping glyph && nc -zv glyph.note-iwato.ts.net 5432` on spore, and remove both files (then `daemon-reload` and restart) before closing the tunnel.

## Guardrails

- Merging doesn't deploy: deploys are manual, via `just switch` or the Deploy workflow. Don't switch a host, merge a PR, or run the Deploy workflow unless asked.

## Committing

- My git config requires signing, which you can't do (it needs an interactive GPG unlock). For commands that create commits, use `git -c commit.gpgsign=false …`, and never change git config to disable signing. Add a `Co-Authored-By:` trailer identifying yourself.

## Updating this file

- When a working solution reached through trial and error would help future sessions in this repo, add it to this file in the PR you're preparing and call it out in the PR description.

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`. It runs alejandra, statix and nil; CI runs it too and fails if it changes or flags anything.

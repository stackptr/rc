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

**Flake inputs:** `nix flake update --commit-lock-file`. The Update workflow (`update.yml`, calling stackptr/actions's reusable `update-flake.yml` pinned by SHA with `secrets: inherit`) does this daily as the `teleotrope` app and merges the PR itself once CI passes (see GitHub apps and rulesets). To update only some inputs, run it by hand with their names: `gh workflow run update.yml -f inputs="nixpkgs home-manager"` (blank updates all; unknown names fail the run). A partial update opens its PR from `gh/update-flake-<run id>`, so neither the daily run nor another partial update overwrites it.

**Dev shell:** `nix develop` provides agenix and just. Claude Code sessions in Zed don't run inside it; prefix devShell tools with `direnv exec .`, e.g. `direnv exec . agenix -e hosts/spore/secrets/foo.age`.

## Key Configuration Details

- Usernames: `mu` on Linux, `corey` on macOS
- SSH key authentication everywhere; keys in `lib/keys.nix`. `keys.<host>` is the host's sshd host key from `hosts/<host>/key.pub` (agenix recipient, deploy known_hosts), never a login key.
- People log in only with the YubiKeys or, from Rhizome and Stroma, a Secure Enclave key (`keys.secureEnclave`, `hosts/<host>/secretive.pub`: Secretive, Touch ID on every use, offered first through Secretive's agent; plain ecdsa, so unlike `verify-required` sshd can't check the Touch ID), or from the iPhone blip, a Secure Enclave key in Rootshell (`keys.phones`, `lib/admin/ssh-<phone>.pub`; Touch ID on every use, plain ecdsa like the Macs'). Rootshell's default ed25519 keys are software keys in the Keychain and can be exported; only its P-256 keys live in the Secure Enclave. The YubiKeys: `keys.yubikeys` (`lib/admin/ssh-yubikey-{a,b}.pub`, FIDO2 `ed25519-sk`), listed with `verify-required`, so every login needs the FIDO2 PIN and a touch. That's mu's and root's `authorized_keys` on the NixOS hosts and the user's on Stroma. The Macs use nixpkgs' OpenSSH (Apple's client can't use security keys) with `IdentityAgent none` for the servers. Their key handles (`ssh-keygen -K` output; not secret, useless without the YubiKey) are committed as `lib/admin/ssh-yubikey-{a,b}`, and home-manager copies them to `~/.ssh/id_ed25519_sk_rc_{a,b}` with mode 0600 (ssh rejects the 0444 store files), so a Mac needs no setup. A replacement YubiKey means new handles and `.pub` files there. SSH to the servers from the Macs shares connections (`ControlMaster auto`, `ControlPersist 10m`), so one PIN and touch covers a host until 10 minutes after its last session; `ssh -O exit <host>` closes it. ykding (`programs.ykding`, pinned in `packages/ykding`, not the Homebrew tap) dings and shows a banner naming who is asking whenever a YubiKey waits for a touch. nixpkgs' `ssh` gets "No route to host" to LAN IPs (macOS Local Network privacy), so use tailnet names.
- Unattended SSH is root only: `keys.deploy` (CI) everywhere, and `keys.clients.glyph` on spore and zeta (`hosts/glyph/client.pub`; private key is glyph's agenix secret `ssh-client-key`, used by mu's SSH config on glyph). Nothing logs into glyph unattended. Tailscale SSH is off (`extraSetFlags = ["--ssh=false"]` on glyph and zeta), so port 22 on tailnet addresses reaches sshd
- Switches don't restart tailscaled on the NixOS hosts (`modules/nixos/tailscale.nix`): deploys run over the tailnet, and a restart mid-switch cancelled a deploy-rs activation on glyph, whose rollback then died partway and left most units stopped. After a Tailscale update, `systemctl restart tailscaled` (expect a tailnet SSH session to drop) or reboot
- glyph's Postgres trusts local connections (socket and 127.0.0.1) but takes tailnet connections only from the clients listed in `hosts/glyph/services/db.nix`, each to its own database and role: today Pocket ID on spore. A new remote client needs its own `pg_hba` line; for ad-hoc `psql`, SSH to glyph and use the socket.
- Tailnet Lock is on, with Rhizome and Stroma as the signing nodes (the Mac app's CLI: `/Applications/Tailscale.app/Contents/MacOS/Tailscale lock ...` unless `tailscale` is on PATH). A new device, or one whose Tailscale state was wiped, shows "Locked out" until a signing node runs the `tailscale lock sign nodekey:... tlpub:...` command from its Machines entry (or from `tailscale lock status` on the new device). Logging back in after key expiry re-signs itself. Disabling the lock needs one of the 10 disablement secrets, in the password manager; without them, `tailscale lock local-disable` on every node is the last resort.
- Deploy workflow runners join the tailnet with `TS_AUTHKEY`, a reusable, ephemeral `tag:ci` auth key signed on a signing node (OAuth clients can't join a locked tailnet). Signing it adds a new trusted signing key to the lock (`(pre-auth key <id>)` in `tailscale lock status`) whose private half is inside `TS_AUTHKEY`, so the secret can sign any node, not just CI runners, and that key stays trusted after the auth key expires. It expires within 90 days and zeta's `tailscale-key-expiry` warns 14 days ahead. To replace it: create the key in the admin console (Settings > Keys: reusable, ephemeral, tag `tag:ci`, 90 days), run `tailscale lock sign <key>` on Rhizome or Stroma, seal the printed key into stackptr/ops for `glyph`, `spore` and `zeta` (`just seal rc <env> TS_AUTHKEY` there, once per environment; merge, and approve the apply), run one Deploy, then revoke the old auth key and remove its signing key with `tailscale lock remove --re-sign=false tlpub:...` (the old `(pre-auth key ...)` line).
- macOS hosts use nix-homebrew with taps pinned as flake inputs (`mutableTaps = false` in `lib/hosts.nix`)
- `ATTIC_TOKEN` (push to the Attic cache) lives in the main-only `attic` environment, which only main's `build` jobs use, and only CI's "Push to Attic" step reads it, after the build, with `attic-client` from a fixed rev in `ci.yml` rather than the flake's lock. Branch, PR and deploy runs read `cache.zx.dev/main` anonymously and never see the token: branch code (its `flake.lock`, or derivations on the unsandboxed macOS runners) must not run alongside it

## Secrets

agenix, least privilege: each host decrypts only its own secrets. The admin recipients are two YubiKeys (`keys.admins` in `lib/keys.nix`; age-plugin-yubikey, PIV slot 1): `a` for daily use, `b` an offline spare. Their identity files in `lib/admin/` only point at the YubiKey slot and aren't secret. Host rules are built by `lib/secrets/mk-host.nix` (`import ./mk-host.nix "<host>" ["<name>" ...]` gives `hosts/<host>/secrets/<name>.age` the host's key plus `keys.admins`); secrets shared by several hosts are written out in `lib/secrets/default.nix` (system; currently none) and `home.nix` (user); secrets no host decrypts, only the admin keys, are in `lib/secrets/admin.nix` (currently `lib/admin/ops-state-passphrase.age`, the backup of stackptr/ops's state passphrase, and the private keys of the GitHub Apps whose keys ops seals into environments, `lib/admin/github-apps/{teleoid,teleotrope,teleopsis,teleozyme}.age` (teleopsis and teleozyme are ops's own plan and apply apps); read one with `agenix -d <file> -i lib/admin/yubikey-a.txt`). teleomycete's key sits beside them as `lib/admin/github-apps/teleomycete.age`, but glyph decrypts it to mint the agents' tokens, so it's also encrypted to glyph and its rule is in `lib/secrets/glyph.nix`. `lib/admin/github-apps/README.md` covers how each key is used and rotated, beside each app’s logo (`<app>.svg`). GitHub shows an app's private key only once, so these are the only copies: to seal one for a repo, pipe it straight in, `(cd ~/Development/rc && direnv exec . agenix -d lib/admin/github-apps/teleoid.age -i lib/admin/yubikey-a.txt) | just seal <repo> approve APPROVER_PRIVATE_KEY` from the ops checkout. A rotated key replaces its file here before it's re-sealed anywhere. restic (`rc.backup`, glyph only) reads `hosts/<host>/secrets/restic-{env,password}.age`: a host that starts backing up needs its own R2 bucket and bucket-scoped token, since R2 tokens can't be limited to a prefix.

```bash
agenix -e hosts/spore/secrets/some-secret.age -i lib/admin/yubikey-a.txt   # edit: PIV PIN, then touch
agenix -r -i lib/admin/yubikey-a.txt                                       # re-encrypt after changing recipients
```
Creating a secret, or replacing one from stdin (`echo -n value | agenix -e ...`), only encrypts and needs no YubiKey. The devShell puts `age-plugin-yubikey` on PATH, which agenix's `age` needs to use YubiKey recipients and identities. `agenix -c` can't check age-plugin recipients and fails on every file, so don't rely on it.

Every host, macOS included, decrypts with one identity: sshd's host key (`/etc/ssh/ssh_host_ed25519_key`, which `hosts/<host>/key.pub` holds; on a Mac, `sudo ssh-keygen -A` creates it). On macOS agenix's darwin module decrypts at boot, before login. There's no home-manager agenix: a user's secret is a system secret with `owner = username`, declared in the host's config, and home-manager reads its path from `osConfig.age.secrets.<name>.path`. aichat is only installed on hosts that declare `aichat-env`.

To add a secret: add its name to the host's list in `lib/secrets/<host>.nix`, create it with `agenix -e hosts/<host>/secrets/<name>.age`, and reference it with `age.secrets.<name>.file`. A new host needs `hosts/<host>/key.pub`, an entry in `lib/keys.nix`, and a `lib/secrets/<host>.nix` imported by `lib/secrets.nix` before it can decrypt anything.

## GitHub apps and rulesets

Three private GitHub Apps act on rc, with a role the rulesets below enforce. rc is one of the repos under stackptr/ops's baseline, each listed in its `repos.nix` and added by the "Onboarding a repo" checklist in its CLAUDE.md. teleomycete and teleoid are installed on the ones with `agents` (rc, actions, zx.dev and flakes), teleotrope on rc only. Only repos the agents may change unattended get agents: pushing needs Contents write, which also covers releases and their assets, and no ruleset guards those, while the agents' token reaches every repo teleomycete is installed on. So resume (whose release PDF `cjohns.com/resume` serves) and llm-profile (whose release bundles I paste into claude.ai) are managed for settings and secrets only, and changed from sessions I supervise. Private repos stay out of ops: rulesets and environments there would need GitHub Pro, and ops's apps would get Administration write over them for little gain. Repository settings (rc's: squash and rebase merges, the PR title as the squash subject, auto-merge, merged branches deleted), rulesets, environments and their variables, workflow permissions and environment secrets are managed by stackptr/ops (`infrastructure/github/`): change them there, not in GitHub's UI, and its daily drift check flags edits made in the UI. ops can't set `has_pull_requests`, which must stay on. App permissions, installations, logos and badge colors are still set by hand: permissions and installations are recorded in ops’s `apps.nix`, logos and colors in `lib/admin/github-apps/`; keep those and this section in step. Each bot commits with its user ID (not the app ID) in its noreply address, `<id>+<slug>[bot]@users.noreply.github.com`; get it with `gh api '/users/<slug>%5Bbot%5D' --jq .id`.

| App | Permissions | Key | Used by | A leaked key could |
|---|---|---|---|---|
| `teleomycete` (346624003) | Contents, Pull requests, Issues R/W | `lib/admin/github-apps/teleomycete.age` (also encrypted to glyph; rule in `lib/secrets/glyph.nix`), minted on glyph (Coding agents) | Paseo and OpenCode agents | push `agents/**` and open PRs, on every repo it's installed on; create or edit releases and tags (Contents write), except tags on repos with "Release tags" (actions); not merge without my approval, not touch `.github/workflows/` |
| `teleotrope` (347049929) | Contents, Pull requests R/W | `update` environment (`UPDATER_CLIENT_ID`, `UPDATER_PRIVATE_KEY`) | `.github/workflows/update.yml` (stackptr/actions's reusable `update-flake.yml`) | push any branch outside `agents/**` and merge PRs once CI passes, without approval |
| `teleoid` | Contents, Pull requests R/W | each agents repo's `approve` environment (`APPROVER_CLIENT_ID`, `APPROVER_PRIVATE_KEY`; one key, the same in every repo) | `.github/workflows/approve.yml` | approve and merge PRs once CI passes, except ones whose latest push is its own; push nowhere |

| Ruleset | Target | Rules | Bypass |
|---|---|---|---|
| Require CI | default branch | the six host builds must pass; no force push | Repository admin |
| Require approval | default branch | PR with 1 approval, stale approvals dismissed, approval of the most recent push; no deletion or force push | Repository admin, `teleotrope` |
| Agent branches | all but the default branch and `agents/**` | restrict creations, updates and deletions; no force push | Repository admin, `teleotrope` (`updaterBypass`), Dependabot (`dependabot`) |
| Agent-only branches | `agents/**` | restrict creations and updates | Repository admin, `teleomycete` (`agentsInstalled`) |

Environments, each limited to `main` with admin bypass off: `glyph` and `zeta` (Deploy; need my approval), `spore` (Deploy; no reviewer, so its daily scheduled deploy runs unattended), `update` (teleotrope), `approve` (teleoid), `attic` (`ATTIC_TOKEN`) and `notify` (`SLACK_BOT_TOKEN`). Every secret is an environment secret, sealed in stackptr/ops's `sealed.json`; there are no repository-level secrets, which any branch's workflows could read, and ops's daily check alerts if one appears.

The same holds for every repo under ops, ops included: no secret is set by hand, so `sealed.json` can restore any of them. ops's own environments hold the credentials every plan and apply runs with:
- `plan`: teleopsis's key, a read-only R2 token, the state passphrase and Hypha's Slack token.
- `production`: teleozyme's key, a read-write R2 token and the passphrase, behind my approval.
- `attic`: a token for ops's own Attic cache (`ops:ops`).

Where to get a value to re-seal:
- the app keys, from `lib/admin/github-apps/`
- the passphrase, from `lib/admin/ops-state-passphrase.age`
- Slack's token, from `hosts/glyph/secrets/slack-bot-token.age`
- new R2 tokens, from Cloudflare (Object Read only, or Read & Write, on `ops-state`)
- a new Attic token, from glyph (`atticd-atticadm make-token --push ops --pull ops`)

Re-seal by piping straight into `just seal` (ops's onboarding checklist). A new value takes effect from the next run, and the old one works until it's revoked: confirm a run on the new value before revoking.

How each kind of PR merges:
- **Agents' (`teleomycete[bot]`, from `agents/*`):** the agent turns on auto-merge; it merges once CI passes and I approve the latest push.
- **Mine (cloud sessions' included):** `approve.yml` runs on `pull_request_target` (from main, so a PR can't change it) and calls stackptr/actions's reusable `approve.yml` (pinned to a release's SHA with `secrets: inherit`; Dependabot bumps it at each actions release; shared by every repo the agents work on), which approves as teleoid when the author is `stackptr`, the branch is in this repo and the PR isn't a draft; each push dismisses it and the next run re-approves. Turn on auto-merge and it merges once CI passes. Open PRs get approved on their next push or reopen.
- **Updates (`teleotrope[bot]`, `gh/update-flake`, or `gh/update-flake-<run id>` for a partial update):** `update.yml` calls stackptr/actions's reusable `update-flake.yml` (pinned to a release's SHA with `secrets: inherit`; Dependabot bumps it), which waits for the required checks and merges with `gh pr merge --admin --match-head-commit`.

Rules that must keep holding:
- `teleomycete` is never a bypass actor except on "Agent-only branches", and never gets Workflows. Without Workflows, GitHub rejects its pushes that change `.github/workflows/`, which is what keeps branch code away from repo-level secrets and environments.
- An app key lives only on glyph (agenix) or in a main-only environment, and the workflow using it runs from main (schedule, dispatch or `pull_request_target`), never checks out PR code, and passes PR fields to scripts only through `env:`.
- Only the admin role and `teleomycete` push `agents/**`, only the admin role, `teleotrope` and Dependabot (its own `dependabot/**`) push other branches, and `teleoid` pushes nowhere.
- "Allow GitHub Actions to create and approve pull requests" stays off.

Learned the hard way:
- Auto-merge waits for a required approval even when the enabling actor may bypass the rule, so a bypass actor has to merge directly; `gh pr merge` checks the merge state itself and refuses a blocked PR unless given `--admin`, which only sends the request (GitHub still applies the rulesets).
- An app's approval counts toward required reviews only if it has write access (Contents: write); Pull requests: write alone shows "Review required".
- A bypass actor skips every rule in its ruleset, so the approval rule is a ruleset of its own, and teleotrope can skip it without skipping CI.
- Pushes from Claude Code cloud sessions count as my admin bypass, but their proxy refuses branch deletion (git and API).
- GitHub rejects an app as a ruleset bypass actor (422 "must be part of the ruleset source") unless it's installed on the repo, or for Dependabot, running there. So ops adds teleomycete to "Agent-only branches" only once it's installed (`agentsInstalled`), and Dependabot to "Agent branches" only on repos with a `dependabot.yml` (`dependabot`).
- Dependabot isn't exempt from rulesets: "Agent branches" rejected its pushes on rc from 23 Oct to 4 Nov 2026 while its runs still reported success. A failed push shows only in `gh api 'repos/stackptr/rc/rulesets/rule-suites?rule_suite_result=fail'`.
- A reusable workflow's `secrets` holds only what the caller passes, even in a job that declares `environment:`: without `secrets: inherit` in the caller, the environment's secrets arrive empty (its variables do arrive).

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

**Did a commit change a host's system?** Compare `scripts/normalized-system.nix` at both commits (`nix eval --raw --file scripts/normalized-system.nix --apply 'f: f { flake = "git+file://<repo>?rev=<sha>"; host = "glyph"; }'`), not the raw toplevel: `system.configurationRevision` and glyph's rc-source copy of the repo (`"${inputs.self}"`) change every host's or glyph's derivation on every commit. `nix eval --file` doesn't call a function with `--argstr`, hence `--apply`; and a Nix path literal there (`/var/empty`) is copied into the store, so it fails where the path doesn't exist: use a string. `git+file` with `rev` works from a detached checkout with no local branch.

**`lib.mkForce` vs `lib.mkDefault`:** a host that must diverge from a value a shared module sets uses `lib.mkForce`; without it Nix errors on the conflicting definitions. A shared module that wants hosts to override freely sets `lib.mkDefault` instead. Example: `modules/base/gc.nix` sets `nix.gc.dates = "weekly"`, and `hosts/spore/default.nix` overrides it with `lib.mkForce "daily"`.

## Monitoring Stack

Grafana, Loki and Prometheus on glyph. Use them before `journalctl` or SSH when investigating failures, slowness or disk issues.

- **Grafana** (glyph:3000, `monitoring.zx.dev` via spore): config in `hosts/glyph/services/grafana.nix`; the image renderer (localhost:8081) backs `get_panel_image`.
- **Loki** (glyph:3100): journald from glyph, spore and zeta via Alloy, oMLX's log from Stroma, plus Claude Code events over OTLP; 30 days.
- **Prometheus** (glyph:9099): scrapes glyph, spore, zeta and Stroma (node_exporter, mactop, json_exporter for oMLX, Alloy; `hosts/Stroma/monitoring.nix`), plus OTLP pushes; 90 days.
- **CI failures**: the `notify` job in `.github/workflows/ci.yml` posts to #alerts as Hypha through `stackptr/actions/slack-notify` (pinned by SHA; needs `SLACK_BOT_TOKEN` from the main-only `notify` environment and `permissions: actions: read`; only runs of main post, and PR failures show on the PR). Test a change to it with `dry-run: true`.
- **Port scan**: `.github/workflows/port-scan.yml` scans every TCP port on spore's public address daily from a GitHub runner and posts to #alerts if one is open that spore's firewall on main doesn't allow, or if nothing is open at all. The expected list comes from evaluating spore's config, so there's nothing to update by hand. Home has no public services to scan beyond glyph's Transmission forward.
- **Alert rules**: `hosts/glyph/services/grafana-alerts.nix` (folder "Alerts", routed to Slack). Add rules there, not in the UI.
- **Dashboards**: JSON in `hosts/glyph/services/dashboards/`: Node, ZFS, Log Explorer, PostgreSQL, Disk Health (SMART), Systemd Units, nginx, Apple Silicon (Stroma).
- **Gatus** (zeta:8080, `status.zx.dev`): out-of-band watchdog in `hosts/zeta/services/gatus.nix` that posts to Slack itself, so it alerts when glyph or Grafana is down. Every minute it checks glyph (reachability, Postgres, Prometheus freshness, Loki ingestion, Grafana through spore), spore, and the public sites through their `*.zx.dev` URLs; the `zx.dev` cert hourly. Hourly, `tailscale-key-expiry.service` asks the Tailscale API (OAuth client in `gatus-env.age`) for node keys expiring within 14 days or servers with expiry enabled, and pushes the result to Gatus's `tailscale/key-expiry` endpoint, which also fires if no result arrives for 3h.

**Slack:** everything posts as the Hypha bot with `chat.postMessage` and its one bot token; nothing uses incoming webhooks. Alerts (Grafana, Gatus) go to #alerts; informational posts (downloads) go to #updates; workflows post through `stackptr/actions/slack-notify` (see CI failures above). The top-level `text` is the notification preview, so every message needs one: a message with only attachments notifies as "[no preview available]". A service on any host sends a notification by publishing to ntfy on glyph (`http://glyph:2586/notifications`, JSON publish built with `jq`): `title` is the preview, `message` is Slack mrkdwn, the first tag is the emoji, `click` is a link, and priority 4 or higher goes to #alerts (`hosts/glyph/services/ntfy-to-slack.jq`). The `agents` topic is the exception: the relay sends it to #agents (by channel ID, from `hosts/glyph/slack.nix`, which Hermes shares) whatever its priority, as plain text (no links or mentions) with the robot emoji, so an agent can't post something that passes for an alert. Agents can't reach ntfy's port (the owner rule under Coding agents); they publish only to that topic, through a loopback nginx on glyph:2588 that accepts nothing else. The token is in `hosts/glyph/secrets/slack-bot-token.age` (the ntfy relay and Grafana), in zeta's `gatus-env.age` as `SLACK_BOT_TOKEN`, in the `notify` environments ops seals from glyph's copy (`infrastructure/github/sealed.json` in stackptr/ops), and in ops's `plan`, set by hand; a rotated token goes to all of them. Hypha's manifest (name, description, color, scopes) and logo are in `lib/admin/slack-apps/`: apply manifest changes on the app's App Manifest page, and upload the icon by hand (`rsvg-convert -w 512 -h 512 hypha.svg`).

**grafana-mcp:** registered in mcpjungle on glyph (`http://127.0.0.1:8095/mcp`) with LogQL, PromQL and dashboard tools. It's read-only (`--disable-write` in `modules/nixos/llm/grafana-mcp.nix`): change alert rules and dashboards in the flake.

**MCPJungle** serves the tool list it fetched when each server registered. `mcpjungle-register` re-registers every server at boot and when a local server's unit changes (`restartTriggers` in `hosts/glyph/services/default.nix`); by hand: `systemctl restart mcpjungle-register`. Re-registering deregisters first, so a server that fails loses its tools and the unit exits non-zero (the "Systemd unit failed" alert fires); `{unit="mcpjungle-register.service"} |= "ERROR"` names it. Servers needing auth take `headers` plus an `environmentFile`.

Registration is authoritative: the unit also deregisters any server not in `services.mcpjungle.servers` (so don't register one by hand), re-applies each server's `disabledTools`, and then recreates the tool groups in `services.mcpjungle.groups`, each served at `/v0/groups/<name>/mcp` (Open WebUI uses `chat`, the coding agents `agents`). Groups are deleted and recreated, not updated: while servers re-sync in parallel, MCPJungle can leave a re-added tool out of a group's endpoint even though `GET /api/v0/tool-groups/<name>/effective-tools` lists it, and `update group` with an unchanged config doesn't repair it. A group that includes a disabled tool can't be created, so the module adds every `disabledTools` entry to each group's `excluded_tools`.

**An MCP server behind `mcp-proxy` fails with `McpError: Connection closed`** (grafana-mcp, and the others in `modules/nixos/llm/` that wrap a stdio server): `mcp-proxy` starts the real server as a child, and that child exited, so the traceback hides its error. Run the child by hand with the module's arguments (e.g. `mcp-grafana --disable-write ...`) to see it, and check whether the last flake update moved its major version: mcp-grafana 2.x dropped `--disable-sift`, and Go CLIs exit on a flag they don't know, so glyph's build passed and the service crash-looped only after the switch.

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


**A unit's start, stop and result:** its own stream (`unit="X.service"`) has only what the unit printed. systemd's lines about it (`Starting`, `Finished`, `Failed with result`, `Deactivated successfully`) are in `{app="systemd", unit="init.scope"}`, and the `Starting`/`Finished`/`Failed to start` ones name the unit's description, not its unit name, so match both: `{host="glyph", app="systemd"} |~ "home-manager-opencode|Home Manager environment for opencode"`. A oneshot with `RemainAfterExit` logs `Stopped`/`Deactivated` for the previous run before each new `Starting`.

To summarise a noisy stream, use grafana-mcp's `query_loki_patterns` (e.g. `{host="glyph", unit="jellyfin.service"}`). Patterns live in Loki's memory, so they only cover logs since Loki last restarted.

### Deploys

Check deploys first when something regressed. Dashboards show them as a purple "Deploys" annotation, and #updates has a ":rocket: <host> deployed <rev>" post for each activation on a NixOS host, with its package changes and a compare link from the previous revision. On a host, `nixos-version --configuration-revision` gives the deployed revision.

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
| `cadvisor` | 12345 (Alloy's `/api/v0/component/prometheus.exporter.cadvisor.units/metrics`) | glyph, spore, zeta | CPU, memory and disk I/O per systemd unit and slice, from cgroups (each host's `services/alloy.nix`; spore and zeta collect `/system.slice/*` only): `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`, `container_memory_rss`, `container_fs_{reads,writes}_bytes_total` and the rest of cAdvisor's cpu, memory and diskIO kinds. `id` is the cgroup path (`/system.slice/navidrome.service`) and `unit` its last part, matching Loki's `unit`. Covers `/system.slice/*`, `agents.slice` and its units, podman's containers in `/machine.slice/*` (`libpod-<id>.scope`; a `podman-<name>.service` holds only conmon) and the root cgroup (`id="/"`, no `unit`). A slice's series include its children, so filter to `.service` and `.scope` units before summing. Disk I/O covers the ext4 root only: ZFS issues pool I/O from its own kernel threads, so it isn't attributed to units. The Systemd Units dashboard plots the top units by CPU, memory and disk I/O |
| `mcpjungle` | 8090 | glyph | MCP gateway tool calls: `mcpjungle_tool_calls_ratio_total{mcp_server_name, tool_name, outcome}` and `mcpjungle_tool_call_latency_seconds`. `outcome="error"` means the gateway couldn't reach or talk to the upstream server, not a tool's own error result. The `_ratio` comes from the OTel unit `"1"`; series appear after a tool's first call |
| `omlx` | 7979/probe | stroma | oMLX via json_exporter, which fetches `http://127.0.0.1:8000/api/status` per scrape with the oMLX sub-key from agenix (`omlx-monitoring-key.age`; a missing or rejected key makes `up` 0): `omlx_requests_{active,waiting}`, `omlx_{requests,prompt_tokens,completion_tokens,cached_tokens}_total`, `omlx_models_{loaded,loading,discovered}`, `omlx_loaded_model_info{model}`, `omlx_model_memory_used_bytes`, `omlx_avg_{prefill,generation}_tokens_per_second`, `omlx_cache_efficiency_percent`, `omlx_info{version}`. Counters reset when oMLX restarts and the averages run from its start; `up == 0` means oMLX isn't answering |
| `open-webui` | push (OTLP) | glyph | `http_server_requests_total`, `http_server_duration_*`, `webui_users_*`; pushed to Prometheus's OTLP receiver, not scraped, so no `up` series |

Which units use the most CPU and memory on a host:
```promql
topk(10, sum by (unit) (rate(container_cpu_usage_seconds_total{host="glyph", unit=~".+\\.(service|scope)"}[5m])))   # cores
topk(10, container_memory_working_set_bytes{host="glyph", unit=~".+\\.(service|scope)"})
```

**A rule that never fires:** Grafana's threshold step (C) tests each series' value, by default `> 0`, so a PromQL filter that leaves zeros (`up == 0`, `x != 1` on a 0/1 gauge) matches series but stays Normal. Query the raw value and set `evaluator` in `mkRule` instead (`grafana-alerts.nix`).

**Picking a port on glyph:** grep the repo and check defaults that aren't declared in Nix. Transmission's RPC takes 9091 (`torrents.zx.dev`), so an exporter there fails with "address already in use".

**`home.zx.dev` returns "400: Bad Request"** (Home Assistant on zeta): since HA 2026.8 the HTTP server settings live in the UI, not `configuration.yaml`. YAML `http:` is imported once, then ignored, so editing it in Nix does nothing. If the import is rolled back (an admin must confirm the new settings within 5 minutes, impossible while logins are broken), HA falls back to defaults and rejects spore's proxy: `{host="zeta", unit="home-assistant.service"} |= "untrusted proxy"` shows `Received X-Forwarded-For header from an untrusted proxy <spore's tailnet IP>`. Fix: open `http://zeta.note-iwato.ts.net:8123` directly (not through spore), then Settings > System > Network > HTTP server: turn on Trust X-Forwarded-For, add `100.64.0.0/10` to Trusted proxies, save, log back in after the restart and confirm within 5 minutes. The Gatus `sites/home-assistant` check expects 401 from `https://home.zx.dev/api/` and fires on a 400.

**AudioMuse-AI** (glyph:8001, `mix.zx.dev` via spore behind Pocket ID; `hosts/glyph/services/audiomuse.nix`): the upstream image as podman containers (flask, and one worker at `--cpus=7 --cpu-shares=256`; each worker runs one album job at a time, so a full re-analysis is faster with three, added in the `workers` list) on glyph's Postgres (database `audiomuse`, over `/run/postgresql`). Only infrastructure is in Nix. At first start it copies every setting, environment ones included, into its `app_config` table, which then overrides the environment: changing an env var in Nix does nothing on an existing database. Change settings in its UI, or for ones the UI doesn't show (like `ENABLE_PROXY_FIX`) `UPDATE app_config SET value = 'true' WHERE key = '...'` and restart both units. With a single uncapped worker the first analysis ran at about 10 tracks/min on a third to half of glyph's 24 cores; AudioMuse sizes its thread pools from the cgroup quota, so `--cpus` sets each worker's threads too. Analysis runs only when started by hand or by a schedule on its Scheduled Tasks page (`/cron`, stored in its `cron` table, in the container's local time); there's no trigger on new tracks. Progress: `audiomuse_tracks_analysed` (a 5-minute timer counts the `score` table into node_exporter's textfile collector) against Navidrome's `db_model_totals{model="media"}`; both are on Homepage. Its own auth is off (Setup Wizard toggle), so `mix.zx.dev`'s Pocket ID is the only gate and anything on the tailnet can use glyph:8001; Navidrome's plugin still sends the API token, ignored while auth is off. If auth is turned back on and admin access is lost: delete the `AUDIOMUSE_USER`/`AUDIOMUSE_PASSWORD` rows from `app_config` and the admin rows from `audiomuse_users`, restart both units, and the Setup Wizard returns. The image tag is pinned; bump it by hand. Gatus's `glyph/audiomuse` checks flask's `/api/health`. A crashing container is caught by the "Systemd unit restart loop" alert, but supervisord inside each container restarts its own processes, so a worker process that crash-loops never reaches systemd: look in Loki.

**Coding agents** (glyph, `hosts/glyph/services/agents.nix`): OpenCode's server (glyph:8890, `code.zx.dev`) and Paseo (glyph:6767, `agents.zx.dev`), both behind Pocket ID on spore. tailscaled's `ts-input` chain, first in filter `INPUT`, accepts everything from tailscale0, so neither `trustedInterfaces` nor any rule in `nixos-fw` filters tailnet traffic; a mangle `INPUT` chain (`opencode-in`) drops tailnet connections to both ports except from spore, plus blip, slate, Stroma and Rhizome (the iPhone, iPad and two Macs) on Paseo's, since its apps can't log in to Pocket ID and connects directly with the password (`glyph.note-iwato.ts.net:6767`, no SSL). The addresses are in `hosts/glyph/tailnet.nix` (db.nix's `pg_hba` uses spore's too); update them if a device re-registers. Paseo also keeps its own password (`paseo-env.age`): without one it lets anything that reaches its port control it, and agents reach it on loopback. On GitHub, agents act as the private `teleomycete` app (Contents, Pull requests and Issues read and write; no Workflows or Administration). `agents-github-token.service`, as its own user, signs a JWT with `lib/admin/github-apps/teleomycete.age` every 20 minutes and writes an installation token to `/run/agents-github/token` (setgid `opencode`, so the agents can read it but not the key); git's credential helper and the `gh` wrapper on the units' `path` read it, and the nono profile grants the directory read-only, since each mint replaces the file. Commits use the bot's user ID in their noreply address, not the app ID. What the app may push and merge is set by rulesets, under GitHub apps and rulesets. Paseo runs Claude Code as the supervisor, on the subscription through `CLAUDE_CODE_OAUTH_TOKEN` in `claude-code-env.age` (from `claude setup-token`; never set `ANTHROPIC_API_KEY`, which bills the API instead), and OpenCode and Pi workers on oMLX without Paseo's tools. Both units run as the unprivileged `opencode` user in `agents.slice`, with `/home`, `/mnt`, `/run/agenix`, `/run/postgresql` and the Nix daemon's socket hidden, other users' processes hidden (`ProtectProc=invisible`), and an iptables owner rule rejecting its TCP to 5432, because Postgres trusts every local connection. The daemon socket matters because builds run as `nixbld` users outside nono, the slice and the owner rule, and fixed-output derivations share the host's network, so an agent could reach Postgres through one; hide it per unit rather than leaving `opencode` out of `nix.settings.allowed-users`, which would break `home-manager-opencode.service` (home-manager's activation runs `nix-build` and `nix-store --add-root` as the user). Every agent process also runs under nono's `agents` profile (Landlock), which grants only `/var/lib/opencode/workspaces` (repositories, and Paseo's worktrees in `.worktrees`), `/var/lib/paseo/opencode-home` (the working directory of Paseo's OpenCode server) and the agents' own state. Never grant the working directory (`--allow-cwd`): Paseo starts some agent processes in the home, and a grant there overlaps nono's denies for `~/.ssh` and the rest, which Landlock can't enforce, so nono refuses to start ("Landlock deny-overlap is not enforceable"), so agents can't read Paseo's home (`/var/lib/paseo`: its local credential and config) even though they share its user. Paseo's Claude agents read `opencode`'s Claude Code config (`CLAUDE_CONFIG_DIR=~/.claude`), which `home-manager.users.opencode` writes by importing `modules/home/development.nix`, the module behind my own Claude Code: the llm-profile `agent` prompt, the `glyph` MCP gateway (overridden to the `agents` tool group, every server but the Obsidian vault, through a loopback nginx on 8099 that serves only that endpoint; the owner rule rejects their TCP to MCPJungle's 8090, where they'd get every server and its unauthenticated admin API, and to obsidian-vault-mcp's 8097; ntfy's 2586 likewise, so they publish only to the `agents` topic through 2588), the permission allowlist, telemetry and llm-profile's skills, plus Paseo's skills from `pkgs.paseo.src` (the nixpkgs package leaves out the `skills/` directory the UI's Orchestration skills installer copies from, so don't install them there). Pi's `models.json`, `settings.json` and `AGENTS.md` (llm-profile `agent-standalone`) are home-manager files too. The units set `SHELL` to bash, since systemd takes it from `opencode`'s passwd entry (nologin) and OpenCode's bash tool runs it; and the profile includes nono's `linux_temp_read`, because the default only grants `/tmp` write, and Claude Code exits ("Temp directory /tmp/claude-968 is not readable") when it can't read its own temp directory. Paseo's `config.json`, the nono profile and Pi's `models.json` and `settings.json` are store symlinks, so settings changed in the UI fail to save: change them in Nix.

**Agent tiers** (glyph, `hosts/glyph/services/agent-tiers.nix`): unattended jobs that need less than Paseo's agents run as a tier's own user: `agent-observe` (Grafana's read tools and rc-source, for alert investigation and log sweeps) or `agent-review` (rc-source only, for PR review). Paseo (`opencode`) is the write tier. Each tier has its home under `/var/lib/agent-<tier>`, a nono profile with no repository and no working directory (only OpenCode's state and the unit's private `/tmp`), its own MCP group (`agents-<tier>`) behind a loopback nginx (8093, 8094), and an owner-matched egress chain (`agent-<tier>-out`) that allows only that proxy, loopback ports in the ephemeral range (OpenCode's `run --standalone` talks to a server it starts on a random port) and oMLX on Stroma by tailnet address, and rejects everything else, DNS included. Their OpenCode config denies bash, edit and web tools, and `OPENCODE_DISABLE_PROJECT_CONFIG` keeps it from loading any other. Jobs run as transient units, as root: `agent-run <tier> opencode run --standalone "<prompt>"` (systemd-run with the same sandboxing as Paseo's units, in `agents.slice`, output and exit status passed back). Tiers deliberately don't get Paseo daemons of their own: Paseo can't switch users, so each would need its own port, password and firewall exception just to show runs nobody watches; the dispatcher keeps the record instead. They share `opencode`'s oMLX sub-key (`opencode-env.age`), so oMLX's log can't tell tiers apart. A new tier is an entry in `tiers` with a free loopback port.

**pgAdmin** (glyph:5050, `db.zx.dev` via spore behind Pocket ID; `hosts/glyph/services/pgadmin.nix`): logs in only through Pocket ID's `pgadmin` OIDC client, and only as the user `preStart` creates (`OAUTH2_AUTO_CREATE_USER` is off). `preStart` also replaces that user's server list with the declared one, so servers added in the UI vanish on restart: add them in Nix. It connects to Postgres as the superuser role `pgadmin` over the socket. pgAdmin asks for a password before trying to connect unless the server has a saved password, passfile, `PassExecCommand` or libpq `Service`, even when `pg_hba` trusts it, so the server entry names a service from `PGSERVICEFILE`. A password saved in the UI wouldn't last anyway: `--replace` recreates the entry on every restart. The module writes `settings` as Python literals into `/etc/pgadmin/config_system.py`, so the client secret is read from `$CREDENTIALS_DIRECTORY` by lines appended with `lib.mkAfter`.

**Agent builder VM** (glyph, `hosts/glyph/services/agent-builder.nix`): agents build and test with Nix in a microvm.nix VM (`microvm@builder.service`, cloud-hypervisor, 6 vCPU, 8 GiB) rather than glyph's daemon, which runs as root and gives fixed-output derivations the host's network. `builder '<command>'` on the units' `path` runs a command there as root over SSH (`10.88.0.2` on the `vm-builder` tap) with a key `agent-builder-key.service` creates in `~/.config/agent-builder`. The VM shares glyph's store read-only as the lower layer of its store overlay and the workspaces read-only at the same paths; its overlay image is deleted before every start. The mangle `builder-in` chain drops everything it sends to private, tailnet, loopback and multicast addresses and all its IPv6, so it reaches the internet (through NAT on `enp5s0`) and nothing of glyph's. It runs in `agents.slice`, inside the agents' memory and CPU budget. Its substituters are `cache.nixos.org` and `cache.zx.dev` through spore.

**Navidrome plugins:** `services.navidrome.withPlugins = p: [ ... ]` picks from `pkgsCross.wasi32.navidromePlugins` (the module's old `plugins` list now fails evaluation with "plugin … does not exist in navidromePlugins" for anything outside that set, so a plugin nixpkgs doesn't package needs its own derivation added there). The wrapper is a `symlinkJoin` of `navidrome-unwrapped` and the plugins, so changing plugins no longer rebuilds Navidrome; the WASM plugins themselves are cross-compiled, so CI builds them into attic.

### Blind spots

Know these before concluding "no data means no problem":
- Grafana and its database run on glyph: if glyph is down, all Grafana alerting is down too (Gatus still alerts). If spore is down, `monitoring.zx.dev` is unreachable but alerting keeps running.
- Per-vhost HTTP status and latency exist only as LogQL over `app="nginx_access"`; the `nginx` job is `stub_status` connection counts.
- Local `just switch` prints switch-to-configuration output only to the terminal; Loki gets the `nixos-deploy` lines and systemd's own unit logs.
- Deploy workflow output lands in the journal after the deploy finishes (timestamped at the end, without `copying path` lines), and only in GitHub Actions if the host was unreachable.
- No metrics for app internals (Jellyfin, Home Assistant, etc.): use `node_systemd_unit_state`, the `cadvisor` job's per-unit CPU and memory, and Loki.
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

## Hermes agent

Hermes Agent (`hosts/glyph/services/hermes.nix`, flake input `hermes-agent` pinned to a release tag; bump it by hand) is a read-only ops agent on glyph: it answers one Slack user in one channel (its own Slack app, not Grafana's bot) and runs cron jobs, on oMLX on Stroma. Its tools are grafana-mcp's read tools and FreshRSS (`packages/freshrss-mcp`, stdio, reading plus marking articles read or starred).

- **State:** `HERMES_HOME` is `/var/lib/hermes/.hermes` (sessions, `state.db`, `cron/jobs.json`, logs); unit `hermes-agent.service`, runs as `hermes`. CLI: `sudo -u hermes -i hermes …` (e.g. `hermes cron list`).
- **Config:** `services.hermes-agent.settings` renders `config.yaml`, merged into the file on disk at activation (keys Nix doesn't set survive); `hermes config set` is refused. Secrets come from agenix env files (`hermes-omlx-env`, `hermes-slack-env`, `hermes-freshrss-env`: the FreshRSS API password Reeder also uses), concatenated into `.env` at activation; the unit restarts when they change. Cron jobs are runtime state (`/cron` in Slack or the CLI), not Nix.
- **Lockdown:** it reads untrusted text (nginx access logs, alert text), so it gets MCP tools only and nothing persists between runs. `platform_toolsets` allowlists the MCP server; `agent.disabled_toolsets` (applied last, and capping per-job cron `enabled_toolsets`) lists every built-in toolset; `mcp_servers.<name>.tools.include` filters each server. Memory, user profile, skill nudges, the background review fork and the curator are off. Chat sees both MCP servers; cron defaults to grafana only, and feed jobs set `enabled_toolsets: [freshrss]`. A job whose `enabled_toolsets` names no MCP server gets every server. A Hermes upgrade can add toolsets the denylist doesn't name: check the tool list after one (`sudo -u hermes -i hermes tools list --platform slack`).

## Guardrails

- Merging doesn't deploy right away. After CI passes on main, `request-deploys.yml` dispatches Deploy for each host whose system changed since its last successful deployment (compared by `scripts/normalized-system.nix`, which sets aside the flake revision and glyph's rc-source copy of the repo). glyph's and zeta's deploys wait for my approval, and Deploy's `supersede` job cancels an older run still waiting for the same hosts. spore has no reviewer, so it's requested only when I pushed the commit (the workflow_run's actor is the repo owner), and deploys right away; the Update workflow's overnight merge, pushed by teleotrope, isn't requested, and the Deploy workflow deploys main to spore daily at 17:00 UTC once CI's spore build has passed on main (skipped if spore already runs main). So a merge of mine reaches spore within minutes and an update within a day, and a branch deployed to spore by hand is replaced by main at the next request or scheduled run. Every activation on a NixOS host posts its nvd package diff and a compare link to #updates through ntfy (`modules/nixos/deploy-marker.nix`). Deploys otherwise run by hand, via `just switch` or the Deploy workflow. Don't switch a host, merge a PR, approve a deployment, or run the Deploy workflow unless asked.

## Committing

- My git config requires signing, which you can't do (it needs an interactive GPG unlock). For commands that create commits, use `git -c commit.gpgsign=false …`, and never change git config to disable signing. Add a `Co-Authored-By:` trailer identifying yourself.

## Updating this file

- When a working solution reached through trial and error would help future sessions in this repo, add it to this file in the PR you're preparing and call it out in the PR description.

## Code style

- All files should end with a newline.
- After executing large changes, run `nix fmt .`. It runs alejandra, statix and nil; CI runs it too and fails if it changes or flags anything.

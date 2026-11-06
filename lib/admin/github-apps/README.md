# GitHub Apps

The GitHub Apps that act on my repositories, with their private keys and logos.

Each `<app>.age` file holds the app's only copy of its private key, because GitHub shows a key just once. They're encrypted to the admin YubiKeys (`keys.admins`), with rules in `lib/secrets/admin.nix`. teleomycete's is the exception: glyph decrypts it to mint the agents' tokens, so it's also encrypted to glyph and its rule is in `lib/secrets/glyph.nix`. stackptr/ops seals each of the other keys into the GitHub environment that uses it.

What each app may do on GitHub is enforced by rulesets and documented under "GitHub apps and rulesets" in rc's `CLAUDE.md`. App permissions and installations are set by hand and recorded in stackptr/ops's `apps.nix`. This file covers the keys and logos; keep all three in step.

| App | Role | Key sealed into | Badge color |
| --- | --- | --- | --- |
| teleomycete | Identity for agent-created work | none: glyph mints its tokens | `#04342C` |
| teleotrope | Flake updater for rc, merges its own PRs | rc's `update` | `#26215C` |
| teleoid | Approves my PRs so they can auto-merge | every agent repo's `approve` | `#4A1B0C` |
| teleopsis | Read-only observer for stackptr/ops | ops's `plan` | `#042C53` |
| teleozyme | Applies approved plans for stackptr/ops | ops's `production` | `#FAC775` |

## teleomycete

The identity agents commit and open PRs as. teleoid never approves its PRs, so agent work always needs my review before it merges.

The key is never sealed into an environment. On glyph, `agents-github-token.service` signs a JWT with it every 20 minutes and writes an installation token to `/run/agents-github/token`, which the agents can read but the key can't be (`hosts/glyph/services/agents.nix`).

## teleotrope

Updates rc's flake inputs daily, or on demand for selected inputs, from `.github/workflows/update.yml`. It runs in rc's main-only `update` environment (`UPDATER_CLIENT_ID`, `UPDATER_PRIVATE_KEY`) and commits as `teleotrope[bot]`.

It opens the PR, waits for the required checks, and merges directly. The app may bypass rc's approval ruleset and nothing else: "Require CI" has no bypass and still applies to the merge.

## teleoid

Approves PRs I author, so they can auto-merge once CI passes, since I can't approve my own PRs. Each agent repo calls stackptr/actions's reusable `approve.yml` on `pull_request_target`, which reads `APPROVER_PRIVATE_KEY` from that repo's main-only `approve` environment. PRs from teleomycete and from forks never match.

## teleopsis

Read-only observer for stackptr/ops. It runs `tofu plan` on every push to main and in a daily drift check. The plan compares live GitHub settings (rulesets, workflow permissions, environments) against the declared baseline, and lists Actions secrets to flag repository-level ones. It never writes.

## teleozyme

Applies approved OpenTofu plans for stackptr/ops: rulesets, workflow permissions, environments, and environment secrets on every baseline repo. It is near-admin on those repos, and runs only from ops's `production` environment after manual approval.

**Any action by teleozyme outside an approved ops deployment is unexpected and should be investigated.**

## Logos

`<app>.svg` is the source for each app's logo. OpenTofu can't manage an app's logo or badge color, so set them by hand under the app's settings, in **Display information**. GitHub accepts PNG, JPG, or GIF only:

```sh
nix shell nixpkgs#librsvg -c rsvg-convert -w 512 -h 512 teleozyme.svg -o /tmp/teleozyme.png
```

Set the badge color to the logo's own background color, from the table above. teleozyme's background is light on purpose, so the most privileged app stands out in timelines and audit logs.

## Adding or rotating a key

1. Generate the key in the app's settings. GitHub shows it only once.
2. Replace `<app>.age` here with agenix before sealing it anywhere. A new app gets its rule in `lib/secrets/admin.nix` (`keys.admins`), or in its host's secrets file, plus `keys.admins`, if a host decrypts it.
3. Seal it from the ops checkout, piping it straight in:
   ```sh
   (cd ~/Development/rc && direnv exec . agenix -d lib/admin/github-apps/teleoid.age -i lib/admin/yubikey-a.txt) | just seal <repo> approve APPROVER_PRIVATE_KEY
   ```
   For teleomycete, deploy glyph instead.
4. Delete the old key from the app's settings.

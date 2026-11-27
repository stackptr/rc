---
name: Workaround
about: Track a workaround for a package broken in nixpkgs, until it can be removed
title: "Workaround: <attr> broken in nixpkgs"
labels: workaround
---

## What breaks

`<attr>` on <hosts> at nixpkgs `<rev>`: <build or test failure>.

```
<the end of the failing build's log>
```

## Workaround

<Pinned to nixpkgs `<rev>` with `scripts/pin-package add <attr>`, or an override in `overlays/<file>.nix`.> PR: #<number>

## Upstream

<The nixpkgs issue or PR that fixes it, or "none found".>

## Remove when

- [ ] <The condition: e.g. CI builds <hosts> with the workaround removed, or the upstream PR reaches nixpkgs-unstable>
- [ ] The workaround is removed: `scripts/pin-package remove <attr>`, or `overlays/<file>.nix` and its entry in `overlays/default.nix`
- [ ] CI passes for <hosts> without it

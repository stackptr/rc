# rc

System configuration flake for NixOS / [nix-darwin][nix-darwin-repo] hosts:

- 🗿 [`glyph`](./hosts/glyph/default.nix): NAS and homelab 
- 🌿 [`Rhizome`](./hosts/Rhizome/default.nix): personal laptop / 14-inch MacBook Pro
- 🍄 [`spore`](./hosts/spore/default.nix): VPS hosted on CloudCone
- 🌀 [`zeta`](./hosts/zeta/default.nix): ARM server / Raspberry Pi 4 Model B

<details>

<summary>Command reference</summary>

`nh` is used for both Linux and macOS:

```shell
nh os switch github:stackptr/rc        # Linux
nh darwin switch github:stackptr/rc    # macOS
```

🗿 `glyph` can build to 🍄 `spore` to work around memory requirements:
```shell
nixos-rebuild switch --flake .#spore --target-host root@spore --build-host localhost
```

</details>

<details>

<summary>CI and deployments</summary>

CI builds all host configurations on every push and PR. On pushes to `main`, the deploy workflow runs automatically after CI succeeds, deploying only the hosts affected by the change:

- Changes under `hosts/{name}/` deploy only that host
- Changes to shared paths (`modules/`, `home/`, `lib/`, `overlays/`, `packages/`, `flake.nix`, `flake.lock`) deploy all hosts

Deploy all hosts manually:
```shell
gh workflow run Deploy
```

Deploy a specific host:
```shell
gh workflow run Deploy -f hosts=glyph
gh workflow run Deploy -f hosts=spore
gh workflow run Deploy -f hosts=zeta
```

</details>

[nix-darwin-repo]: https://github.com/nix-darwin/nix-darwin

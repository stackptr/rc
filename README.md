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

CI evaluates and builds every host on every push and PR. After CI passes on main, the Request deploys workflow asks to deploy each host whose system changed since its last deployment. glyph's and zeta's requests wait for approval, and a newer request replaces one still waiting; spore deploys right away, but only for commits I push, and the overnight flake update reaches it with its daily scheduled deploy. Each NixOS host posts its package changes to Slack when it activates. To deploy by hand, run the Deploy workflow and tick the hosts to deploy, or from the CLI:
```shell
gh workflow run Deploy -f glyph=true -f spore=true -f zeta=true
gh workflow run Deploy -f spore=true
```

</details>

[nix-darwin-repo]: https://github.com/nix-darwin/nix-darwin

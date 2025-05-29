# rc

System configuration flake for NixOS / [nix-darwin][nix-darwin-repo] hosts:

- 🗿 [`glyph`](./hosts/glyph/default.nix): NAS and homelab 
- 🌧️ [`Petrichor`](./hosts/Petrichor/default.nix): workstation / 16-inch MacBook Pro
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

</details>

[nix-darwin-repo]: https://github.com/LnL7/nix-darwin

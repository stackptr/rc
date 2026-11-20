{
  config,
  pkgs,
  lib,
  ...
}: {
  # Tailscale split DNS sends ts.zx.dev to this server, which rewrites
  # <host>.ts.zx.dev to <host>.note-iwato.ts.net and asks MagicDNS. Forward
  # only the rewritten names: a ts.zx.dev name the rewrite leaves alone (the
  # apex, say) would go back to MagicDNS, which routes it here again. On
  # 2026-11-12 such a loop filled tailscaled's DNS queue and broke all name
  # resolution on glyph. Unrewritten names now fail here instead.
  services.coredns = {
    enable = true;
    config = ''
      ts.zx.dev {
        rewrite stop {
          name regex (.*)\.ts\.zx\.dev {1}.note-iwato.ts.net
          answer auto
        }

        forward note-iwato.ts.net 100.100.100.100
        prometheus 127.0.0.1:9153
      }
    '';
  };
}

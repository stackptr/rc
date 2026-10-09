{
  config,
  pkgs,
  lib,
  ...
}: {
  services.coredns = {
    enable = true;
    config = ''
         ts.zx.dev {
           rewrite stop {
      name regex (.*)\.ts\.zx\.dev {1}.note-iwato.ts.net
      answer auto
           }

           forward . 100.100.100.100
           prometheus 127.0.0.1:9153
         }
    '';
  };
}

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
      name regex (.*)\.ts\.zx\.dev {1}.rove-duck.ts.net
      answer auto
           }

           forward . 100.100.100.100
         }
    '';
  };
}

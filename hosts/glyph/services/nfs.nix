{
  config,
  pkgs,
  ...
}: {
  services.nfs.server = {
    enable = true;
    exports = let
      dir = "/srv";
      tailnetCIDR = "100.64.0.0/10";
    in ''
      ${dir} ${tailnetCIDR}(rw,fsid=0,no_subtree_check,async)
    '';
  };
}

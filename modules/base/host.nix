{lib, ...}: {
  options.rc.host.name = lib.mkOption {
    type = lib.types.str;
    example = "Rhizome";
    description = ''
      The machine's hostname, set by the host builder (lib/hosts.nix) on
      every host. nix-darwin leaves `networking.hostName` null unless a host
      sets it, so home-manager modules read this instead, through
      `osConfig.rc.host.name`.
    '';
  };
}

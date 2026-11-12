# aarch64-linux builder: a NixOS VM (nix-darwin's linux-builder) that builds
# natively on the M5 Ultra, much faster than glyph's qemu binfmt or zeta
# itself. Stroma's own daemon hands it aarch64-linux builds, so glyph uses it
# by sending those builds to Stroma (nix.buildMachines in hosts/glyph).
{
  config,
  keys,
  ...
}: {
  nix.linux-builder = {
    enable = true;
    # These only change the VM's launch script, not its NixOS system, so the
    # image still comes from cache.nixos.org. Changing the guest system itself
    # (nix.linux-builder.config beyond virtualisation.*) means building it,
    # which needs a working Linux builder first.
    config.virtualisation = {
      cores = 16;
      darwin-builder = {
        memorySize = 16 * 1024;
        diskSize = 100 * 1024;
      };
    };
  };

  # glyph's daemon logs in with its client key (keys.clients.glyph), limited
  # to the Nix daemon protocol. The user is a trusted Nix user, so this key
  # can add anything to Stroma's store.
  users.users.${config.system.primaryUser}.openssh.authorizedKeys.keys = [
    ''restrict,command="${config.nix.package}/bin/nix-daemon --stdio" ${keys.clients.glyph}''
  ];
}

# A NixOS host's system derivation, minus the two things that change on
# every commit: the flake revision (system.configurationRevision) and glyph's
# copy of the repo for rc-source. Two commits that give a host the same
# derivation here leave its running system unchanged, so request-deploys.yml
# compares this at the host's last deployed commit and at main's head.
#
#   nix eval --raw --file scripts/normalized-system.nix \
#     --apply 'f: f { flake = "git+file://'"$PWD"'?rev=<sha>"; host = "glyph"; }'
{
  flake,
  host,
}: let
  system = (builtins.getFlake flake).nixosConfigurations.${host}.extendModules {
    modules = [
      ({
        lib,
        options,
        ...
      }: {
        config = lib.mkMerge [
          {system.configurationRevision = lib.mkForce null;}
          # A string, not a path literal, so evaluating doesn't copy anything
          (lib.optionalAttrs (options.services ? rc-source-mcp) {
            services.rc-source-mcp.sourcePath = lib.mkForce "/var/empty";
          })
        ];
      })
    ];
  };
in
  system.config.system.build.toplevel.drvPath

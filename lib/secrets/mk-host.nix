# Rules for a host's own secrets: hosts/<host>/secrets/<name>.age, encrypted
# to that host's key and the admin YubiKeys, and nothing else.
host: names: let
  keys = import ../keys.nix;
in
  builtins.listToAttrs (map (name: {
      name = "hosts/${host}/secrets/${name}.age";
      value.publicKeys = [keys.${host}] ++ keys.admins;
    })
    names)

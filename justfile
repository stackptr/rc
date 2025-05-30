# Build the system config and switch to it when running `just` with no args
default: switch

# Substitute work laptop hostname if necessary
hostname := `[ "$(hostname | cut -d "." -f 1)" = "RL-17745394" ] && echo "Petrichor" || hostname | cut -d "." -f 1`

# TODO: `nh` can't specify the flake attribute?
[macos]
switch host=hostname:
  sudo darwin-rebuild switch --flake .#{{host}}

[linux]
switch host=hostname:
  nh os switch .#{{host}}

update:
  nix flake update --commit-lock-file

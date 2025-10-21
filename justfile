# Build the system config and switch to it when running `just` with no args
default: switch

hostname := `hostname | cut -d "." -f 1`

[macos]
switch host=hostname:
  nh darwin switch .#darwinConfigurations.{{host}}

[linux]
switch host=hostname:
  nh os switch .#nixosConfigurations.{{host}}

update:
  nix flake update --commit-lock-file

switch-remote target-host build-host="localhost":
  nh os switch --flake .#{{target-host}} --target-host root@{{target-host}} --build-host {{build-host}}

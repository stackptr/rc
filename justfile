# Build the system config and switch to it when running `just` with no args
default: switch

# Substitute work laptop hostname if necessary
hostname := `h=$(hostname | cut -d "." -f 1); case "$h" in LOB-*) echo "lobtop";; *) echo "$h";; esac`

[macos]
switch host=hostname:
  nh darwin switch --hostname {{host}} . --ask

[linux]
switch host=hostname:
  nh os switch --hostname {{host}} . --ask

update:
  nix flake update --commit-lock-file

switch-remote target-host build-host="localhost":
  nh os switch --target-host root@{{target-host}} --build-host {{build-host}} --hostname {{target-host}} .

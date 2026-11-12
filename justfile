# Build the system config and switch to it when running `just` with no args
default: switch

# Substitute work laptop hostname if necessary
hostname := `h=$(hostname | cut -d "." -f 1); case "$h" in LOB-*) echo "lobtop";; *) echo "$h";; esac`

# Build, show the diff, and ask before activating
switch host=hostname: (_switch host "--ask")

# Build and activate without asking
apply host=hostname: (_switch host)

[macos]
_switch host *flags:
  nh darwin switch --hostname {{host}} . {{flags}}

[linux]
_switch host *flags:
  nh os switch --hostname {{host}} . {{flags}}

update:
  nix flake update --commit-lock-file

switch-remote target-host build-host="localhost":
  nh os switch --target-host root@{{target-host}} --build-host {{build-host}} --hostname {{target-host}} .

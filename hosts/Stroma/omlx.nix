# oMLX (LLM inference server for Apple Silicon), installed from its own
# Homebrew tap and run headless by launchd instead of the menubar app.
#
# The formula pip-installs a large, fast-moving Python dependency tree
# (git-pinned mlx-lm, mlx-audio, Rust extensions), so it isn't packaged in
# Nix. Its version is still pinned: the tap is the homebrew-omlx flake input,
# and the formula installs a tagged release by checksum. Update with
# `nix flake update homebrew-omlx`.
#
# State stays in basePath: models, settings.json (pinned models, aliases,
# API keys), caches and logs/server.log. The flags below are written back
# into settings.json on each start; everything else there is edited in the
# admin dashboard (http://127.0.0.1:8000/admin).
{
  config,
  inputs,
  ...
}: let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  basePath = "${home}/.omlx";
  brewBin = "${config.homebrew.prefix}/bin";
in {
  nix-homebrew.taps."jundot/homebrew-omlx" = inputs.homebrew-omlx;
  homebrew.brews = ["jundot/omlx/omlx"];

  # A daemon rather than a user agent: Stroma usually runs without anyone
  # logged in, and an agent only starts at login.
  launchd.daemons.omlx.serviceConfig = {
    ProgramArguments = [
      "${brewBin}/omlx"
      "serve"
      # Explicit, so it doesn't depend on the menubar app's base-path file
      "--base-path"
      basePath
      # Loopback only: oMLX then needs no API key, and nothing outside
      # Stroma can reach it.
      "--host"
      "127.0.0.1"
      "--port"
      "8000"
    ];
    UserName = user;
    EnvironmentVariables = {
      HOME = home;
      PATH = "${brewBin}:/usr/bin:/bin:/usr/sbin:/sbin";
      # Tells oMLX launchd restarts it, so the dashboard's restart button
      # works (as under `brew services`).
      OMLX_SUPERVISED = "launchd";
    };
    RunAtLoad = true;
    KeepAlive = true;
    # oMLX writes its own log to ${basePath}/logs/server.log; this catches
    # startup failures before logging is configured.
    StandardOutPath = "${basePath}/logs/launchd.log";
    StandardErrorPath = "${basePath}/logs/launchd.log";
  };
}

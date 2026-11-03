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
  pkgs,
  ...
}: let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  basePath = "${home}/.omlx";
  brewBin = "${config.homebrew.prefix}/bin";
  # Points at the installed keg, e.g. ../Cellar/omlx/0.7.1rc1
  optLink = "${config.homebrew.prefix}/opt/omlx";
in {
  # preshed 3.0.14 (2026-10-24) breaks the formula's install-time
  # `spacy.load('en_core_web_sm')` check with "OverflowError: Python int too
  # large to convert to C ssize_t", so `brew bundle` fails to upgrade oMLX
  # and the switch fails. Pin it in every pip step until the formula does
  # (jundot/omlx#4831); --replace-fail flags when the formula changes.
  nix-homebrew.taps."jundot/homebrew-omlx" = pkgs.applyPatches {
    name = "homebrew-omlx";
    src = inputs.homebrew-omlx;
    postPatch = ''
      substituteInPlace Formula/omlx.rb --replace-fail \
        '"--no-binary", no_binary]' \
        '"--no-binary", no_binary, "preshed==3.0.13"]'
    '';
  };
  homebrew.brews = ["jundot/omlx/omlx"];

  # A daemon rather than a user agent: Stroma usually runs without anyone
  # logged in, and an agent only starts at login.
  launchd.daemons.omlx.serviceConfig = {
    ProgramArguments = [
      # The keg's opt/ link, as the formula's own service uses: bin/omlx
      # can be taken by something else (the menubar app installs its CLI
      # there), and then `brew link` fails and bin/omlx isn't Homebrew's.
      "${config.homebrew.prefix}/opt/omlx/bin/omlx"
      "serve"
      # Explicit, so it doesn't depend on the menubar app's base-path file
      "--base-path"
      basePath
      # All interfaces, so Open WebUI on glyph reaches it over the tailnet
      # (http://stroma.note-iwato.ts.net:8000/v1). On anything but a
      # loopback-only bind oMLX requires an API key for every request
      # except /health, local ones included.
      "--host"
      "0.0.0.0"
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

  # Activation runs `brew bundle` with upgrade and cleanup
  # (homebrew.onActivation in modules/darwin/rc.nix), so a switch that moves
  # the homebrew-omlx input installs a new keg and deletes the one the daemon
  # is running from. The daemon keeps serving the API from memory, but /admin
  # reads its templates from disk and returns 500 (models.zx.dev) until
  # oMLX restarts. Restart it when the keg changed. Activation is one script
  # that runs preActivation first and postActivation after the homebrew step.
  system.activationScripts.preActivation.text = ''
    omlxKegBefore=$(readlink ${optLink} || true)
  '';
  system.activationScripts.postActivation.text = ''
    if [ "$(readlink ${optLink} || true)" != "''${omlxKegBefore:-}" ]; then
      echo "restarting oMLX: Homebrew changed it to $(readlink ${optLink})" >&2
      launchctl kickstart -k system/${config.launchd.daemons.omlx.serviceConfig.Label} || true
    fi
  '';
}

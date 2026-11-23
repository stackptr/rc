# oMLX (LLM inference server for Apple Silicon), installed from its own
# Homebrew tap and run headless by launchd instead of the menubar app.
#
# The formula pip-installs a large, fast-moving Python dependency tree
# (git-pinned mlx-lm, mlx-audio, Rust extensions), so it isn't packaged in
# Nix. Its version is still pinned: the tap is the homebrew-omlx flake input,
# and the formula installs a tagged release by checksum. Update with
# `nix flake update homebrew-omlx`.
#
# State stays in basePath: models, caches, logs/server.log, settings.json
# and model_settings.json (per-model settings, keyed by the model's
# directory name). oMLX rewrites both files from the admin dashboard
# (http://127.0.0.1:8000/admin), so they can't be store symlinks. Instead
# `settings` and `modelSettings` below are deep-merged into them before each
# start: declared keys win, and everything else (API keys and sub-keys,
# server_aliases, models' pinned/default flags) stays editable in the
# dashboard. A dashboard change to a declared key lasts until the next
# restart. Declare only values that differ from oMLX's defaults, so new
# defaults arrive with upgrades.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
  basePath = "${home}/.omlx";
  brewBin = "${config.homebrew.prefix}/bin";
  # Points at the installed keg, e.g. ../Cellar/omlx/0.7.1rc1
  optLink = "${config.homebrew.prefix}/opt/omlx";

  json = pkgs.formats.json {};

  settings = {
    server = {
      # All interfaces, so Open WebUI on glyph reaches it over the tailnet
      # (http://stroma.note-iwato.ts.net:8000/v1). On anything but a
      # loopback-only bind oMLX requires an API key for every request
      # except /health, local ones included.
      host = "0.0.0.0";
      port = 8000;
    };
  };

  modelSettings.models = {
    "Qwen3.8-27B-MTPLX-Optimized-Quality" = {
      temperature = 1.0;
      top_p = 0.95;
      top_k = 20;
    };
    "gemma-4-26B-A4B-it-QAT-MLX-4bit" = {
      temperature = 1.0;
      top_p = 0.95;
      top_k = 64;
    };
    "Inkling-2-Mini-oQ6e-mtp" = {
      temperature = 1.0;
      mtp_enabled = true;
    };
  };

  # A missing file starts from {}; jq's `*` merges objects recursively and
  # replaces arrays. Written to a temp file and renamed, as oMLX does, with
  # its 0600 mode (settings.json holds the API keys).
  mergeInto = file: declared: ''
    { cat ${file} 2>/dev/null || echo '{}'; } \
      | ${lib.getExe pkgs.jq} --slurpfile declared ${declared} '. * $declared[0]' \
      > ${file}.nix.tmp
    mv ${file}.nix.tmp ${file}
  '';
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
  # The script is in the store, and changes with the declared settings, so a
  # switch that changes them reloads the daemon.
  launchd.daemons.omlx.script = ''
    set -eu
    # oMLX creates it on first start, but the merge below runs before that
    mkdir -p ${basePath}
    umask 077
    ${mergeInto "${basePath}/settings.json" (json.generate "omlx-settings.json" settings)}
    ${mergeInto "${basePath}/model_settings.json" (json.generate "omlx-model-settings.json" modelSettings)}
    # The keg's opt/ link, as the formula's own service uses: bin/omlx can
    # be taken by something else (the menubar app installs its CLI there),
    # and then `brew link` fails and bin/omlx isn't Homebrew's. --base-path
    # is explicit so it doesn't depend on the menubar app's base-path file.
    exec ${optLink}/bin/omlx serve --base-path ${basePath}
  '';
  launchd.daemons.omlx.serviceConfig = {
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

self: super: {
  systemdWithBridge = super.systemd.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        mkdir -p "$out/lib/systemd"
        # Put the helper where systemd-run --pipe expects it
        if [ -x "$out/bin/systemd-stdio-bridge" ]; then
          ln -sf "$out/bin/systemd-stdio-bridge" \
                 "$out/lib/systemd/systemd-stdio-bridge"
        fi
      '';
    passthru = old.passthru or {};
  });
}

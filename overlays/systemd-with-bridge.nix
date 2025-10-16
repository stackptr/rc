self: super: {
  systemdWithBridge = super.systemd.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        mkdir -p $out/lib/systemd
        # put the helper where systemd-run --pipe expects it, in the same output
        ln -s $out/bin/systemd-stdio-bridge $out/lib/systemd/systemd-stdio-bridge
      '';
  });
}

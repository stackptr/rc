self: super: {
  daisydisk = super.daisydisk.overrideAttrs (old: {
    version = "4.32";
    src = super.fetchzip {
      url = "https://daisydiskapp.com/download/DaisyDisk.zip";
      hash = "sha256-2QhaY4oQV+bkvcyC88Zsk7eZJ6dySsb5G2+juH8HNjI=";
      stripRoot = false;
    };
  });
}

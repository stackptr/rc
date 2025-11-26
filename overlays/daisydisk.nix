self: super: {
  daisydisk = super.daisydisk.overrideAttrs (old: {
    version = "4.32";
    src = super.fetchzip {
      url = "https://daisydiskapp.com/download/DaisyDisk.zip";
      hash = "sha256-HRW851l3zCq43WmLkElvVlIEmfCsCUMFw/LL2cPa2Xk=";
      stripRoot = false;
    };
  });
}

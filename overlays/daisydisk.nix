self: super: {
  daisydisk = super.daisydisk.overrideAttrs (old: {
    version = "4.34.2";
    src = super.fetchzip {
      url = "https://daisydiskapp.com/download/DaisyDisk.zip";
      hash = "sha256-lSV367twsKDp0e5TsVYfjYO5GPcjtteBCxmUIOrz+0E=";
      stripRoot = false;
    };
  });
}

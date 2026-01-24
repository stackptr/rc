self: super: {
  daisydisk = super.daisydisk.overrideAttrs (old: {
    version = "4.32";
    src = super.fetchzip {
      url = "https://daisydiskapp.com/download/DaisyDisk.zip";
      hash = "sha256-YkXjaDbnwkQUsfhzCA5xQ6C6NGjQV6qj7znyjcKgwIg=";
      stripRoot = false;
    };
  });
}

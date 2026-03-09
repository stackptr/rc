{pkgs, ...}: {
  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
    pinentry.package = with pkgs;
      if stdenv.isDarwin
      then pinentry_mac
      else pinentry-tty;
  };
}

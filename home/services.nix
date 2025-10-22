{pkgs, ...}: {
  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    pinentry.package = with pkgs;
      if stdenv.isDarwin
      then pinentry_mac
      else pinentry-tty;
  };
}

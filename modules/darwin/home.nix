{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    chatgpt
    claude-desktop
    daisydisk
    github-desktop
    gitify
    m-cli
    mas
    mochi
    slack
    the-unarchiver
    whatsapp-for-mac
    zoom-us
  ];
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  system.startOnActivation = {
    "FastScripts" = "${pkgs.fastscripts}/Applications/FastScripts.app/";
    "Ice" = "${pkgs.ice-bar}/Applications/Ice.app/";
    "Gitify" = "${pkgs.gitify}/Applications/Gitify.app/";
    "Hand Mirror" = "/Applications/Hand\ Mirror.app/";
    "PopClip" = "/Applications/PopClip.app/";
    "Scroll Reverser" = "${pkgs.scroll-reverser}/Applications/Scroll\ Reverser.app/";
    "SoundSource" = "${pkgs.soundsource}/Applications/SoundSource.app/";
    "Tailscale" = "/Applications/Tailscale.app/";
  };
}

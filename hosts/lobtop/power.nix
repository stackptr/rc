# lobtop sits at the desk on AC with the lid open, and stays reachable over the
# tailnet (T3 Code sessions from outside the home), so it never idle-sleeps on
# AC. Not power.sleep.computer: nix-darwin applies it with `systemsetup
# -setComputerSleep`, which covers battery too. `pmset -c` changes only the AC
# profile, so the laptop still sleeps on battery. Closing the lid still sleeps
# it (no clamshell display).
{
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -c sleep 0 displaysleep 10
  '';
}

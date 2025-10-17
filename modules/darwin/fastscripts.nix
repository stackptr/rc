{
  config,
  lib,
  pkgs,
  nixDarwin,
  ...
}:
with lib; let
  cfg = config.programs.fastscripts;
  # TODO: This seems bad?
  text = import "${nixDarwin}/modules/lib/write-text.nix" {
    inherit lib;
    mkTextDerivation = pkgs.writeText;
  };
  userScriptActivation = t: let
    user = lib.escapeShellArg config.system.primaryUser;
    target = escapeShellArg t;
  in ''
    if ! diff ${config.system.build.fastscripts}/user/Library/Scripts/${target} ~${user}/Library/Scripts/${target} &> /dev/null; then
      if test -L ~${user}/Library/Scripts/${target}; then
        sudo --user=${user} -- rm ~${user}/Library/Scripts/${target}
      fi
      sudo --user=${user} -- mkdir -p ~${user}/Library/Scripts/"$(dirname ${target})"
      sudo --user=${user} -- cp -f ${config.system.build.fastscripts}/user/Library/Scripts/${target} ~${user}/Library/Scripts/${target}
    fi
  '';
  userScripts = filter (f: f.enable) (attrValues config.programs.fastscripts.userScripts);
  plistFile = config.programs.fastscripts.plistFile;
in {
  options.programs.fastscripts = {
    enable = mkEnableOption "FastScripts";

    userScripts = mkOption {
      type = types.attrsOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked in {file}`~/Library/Scripts`.
      '';
    };

    plistFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Plist file to be imported into FastScripts settings. This is useful to persist binary data such as the
        ScriptKeyboardShortcuts key/data pair.

        This file can be obtained using: `plutil -convert xml1 -o - ~/Library/Preferences/com.red-sweater.fastscripts.plist > fastscripts.xml`.
      '';
    };

    startOnActivation = mkEnableOption "starting FastScripts on activation";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.fastscripts];
    system.build.fastscripts =
      pkgs.runCommand "fastscripts"
      {preferLocalBuild = true;}
      ''
        mkdir -p $out/user/Library/Scripts
        cd $out/user/Library/Scripts
        ${concatMapStringsSep "\n" (attr: ''
            mkdir -p "$(dirname ${escapeShellArg attr.target})"
            ln -s ${escapeShellArgs [attr.source attr.target]}
          '')
          userScripts}
      '';
    system.startOnActivation = mkIf cfg.startOnActivation {
      "FastScripts" = "${pkgs.fastscripts}/Applications/FastScripts.app/";
    };
    system.activationScripts.postActivation.text = let
      user = lib.escapeShellArg config.system.primaryUser;
    in
      mkIf (userScripts != [] || plistFile != null) ''
        ${optionalString (userScripts != []) ''
          echo "setting up fastscripts user scripts..."
          sudo --user=${user} -- mkdir -p ~${user}/Library/Scripts
          ${concatMapStringsSep "\n" (attr: userScriptActivation attr.target) userScripts}
        ''}

        ${optionalString (plistFile != null) ''
          echo "importing fastscripts plist file..."
          sudo --user=${user} -- defaults import com.red-sweater.fastscripts "${plistFile}"
        ''}
      '';
  };
}

{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      enableUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        bradlc.vscode-tailwindcss
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        # "expo.vscode-expo-tools"
        github.github-vscode-theme
        # "ms-playwright.playwright"
        yoavbls.pretty-ts-errors
        streetsidesoftware.code-spell-checker
      ];
      userSettings = {
        "workbench.colorTheme" = "GitHub Dark Default";
        "workbench.startupEditor" = "none";
      };
    };
  };
}

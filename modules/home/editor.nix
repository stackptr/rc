{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.rc.editor;
in {
  options = {
    rc.editor = {
      enable = lib.mkEnableOption "editor configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [catppuccin-nvim lualine-nvim];
      extraLuaConfig = ''
        require("catppuccin").setup {
          flavour = "mocha",
          color_overrides = {
              mocha = {
                  base = "#000000",
                  mantle = "#000000",
                  crust = "#000000",
              },
          },
        }
        vim.cmd.colorscheme "catppuccin"
        require("lualine").setup {
            options = {
                theme = "catppuccin",
                component_separators = "",
                section_separators = { left = '', right = '' },
            }
        }
      '';
    };

    programs.zsh.shellAliases = {
      vim = "${lib.getExe config.programs.neovim.package}";
    };
  };
}

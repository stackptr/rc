{pkgs, ...}: {
  imports = [
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        strict_env = true;
        hide_env_diff = true;
      };
    };
  };

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

  programs.nushell.enable = true;
}

-- Ghostty's `background-opacity` only applies to cells painted with the
-- terminal's *default* background colour. Colorschemes paint an explicit
-- background into every cell, which is fully opaque, so transparency has to be
-- opted into per scheme. Schemes without an option are handled by the
-- ColorScheme autocmd in lua/config/autocmds.lua.
return {
  -- add gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    opts = { transparent_mode = true },
  },
  {
    "rebelot/kanagawa.nvim",
    opts = {
      transparent = true,
      -- `transparent` only clears Normal. The gutter (LineNr, SignColumn,
      -- FoldColumn and every diagnostic/git sign) is painted from
      -- ui.bg_gutter, so clear that too or the left edge stays opaque.
      colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
    },
  },
  { "savq/melange-nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "gruvbox",
      -- colorscheme = "melange",
      colorscheme = "kanagawa-wave",
    },
  },
}

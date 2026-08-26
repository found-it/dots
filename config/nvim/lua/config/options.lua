-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
-- opt.wrap = true

-- Neovim maps *.tmpl to `template` and does not recognise .gotmpl/.gohtml at all,
-- so gopls never sees them as Go templates. Must match gopls' templateExtensions
-- in lua/plugins/go.lua.
vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
  },
})

-- Python LSP. Must be set here (options load before lazy resolves specs) because
-- lazyvim.plugins.extras.lang.python reads this at spec-eval time.
-- basedpyright is a pyright fork that adds inlay hints, which pyright does not
-- implement at all. Strictness is dialled back in lua/plugins/python.lua.
vim.g.lazyvim_python_lsp = "basedpyright"

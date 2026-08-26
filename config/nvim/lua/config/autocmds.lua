-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- yamlls formats on save and converts single quotes to double quotes
vim.api.nvim_create_autocmd("FileType", {
  pattern = "yaml",
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Match the terminal's background opacity (ghostty `background-opacity`).
-- Ghostty only blends cells drawn with the *default* background colour, so the
-- editor background groups have to have their `bg` unset - then nvim emits the
-- default background and ghostty (through tmux) blends it. Colorschemes with a
-- transparency option are configured in lua/plugins/colorscheme.lua; this is
-- the net for the ones that don't have one and for groups they miss.
-- Floats, popups and the statusline are deliberately left opaque so they stay
-- readable against whatever is behind the window.
local transparent_groups = {
  "Normal",
  "NormalNC",
  "EndOfBuffer",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "LineNrAbove",
  "LineNrBelow",
  "CursorLineNr",
  "MsgArea",
  "TabLineFill",
  "WinBar",
  "WinBarNC",
}

local function set_transparent_background()
  for _, group in ipairs(transparent_groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    if not vim.tbl_isempty(hl) and hl.bg ~= nil then
      hl.bg, hl.ctermbg = nil, nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparent_background", { clear = true }),
  callback = set_transparent_background,
})

-- autocmds.lua is sourced on VeryLazy, after the colorscheme has already been
-- applied, so the autocmd above would not have fired for it yet.
set_transparent_background()

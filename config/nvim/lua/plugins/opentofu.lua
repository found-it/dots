return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = { enabled = false }, -- disable the default
        tofu_ls = {}, -- lspconfig default cmd/filetypes are fine
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "tofu-ls" } },
  },
}

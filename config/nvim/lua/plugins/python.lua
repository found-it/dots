-- Python: LazyVim's `lang.python` extra is imported in config/lazy.lua. It wires up
-- the type checker, ruff (as an LSP), venv-selector, neotest-python and dap-python.
--
-- Two things it leaves broken or unset, and one strictness default worth changing.
return {
  -- The extra calls `require("dap-python").setup("debugpy-adapter")` but never asks
  -- Mason to install debugpy, and it disables mason-nvim-dap's python handler that
  -- would otherwise have covered it. Without this, every Python debug session fails
  -- with a missing-executable error. (The Go extra does ensure `delve` — Python is
  -- simply an oversight upstream.)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "debugpy" } },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                -- basedpyright ships `recommended` by default, which flags every
                -- missing annotation as a warning -- 6 warnings on a clean 10-line
                -- file. `standard` is the pyright-equivalent level.
                typeCheckingMode = "standard",
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
        },
      },
    },
  },

  -- LazyVim sets no python formatter, so formatting falls through to `lsp_format`
  -- and the ruff LSP. That formats, but never sorts imports -- organize-imports is
  -- a separate code action ruff's server only runs on request. Going through conform
  -- applies the same three steps `ruff check --fix && ruff format` would, on save.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
      },
    },
  },
}

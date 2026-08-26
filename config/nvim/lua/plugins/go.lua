-- Go: LazyVim's `lang.go` extra is imported in config/lazy.lua. That extra wires up
-- gopls, treesitter, conform (goimports + gofumpt) and nvim-lint (golangci-lint),
-- but its DAP and neotest blocks are `optional = true` — they only take effect once
-- the `dap.core` and `test.core` extras are also imported (they now are).
--
-- This file layers on what the extra leaves out.

-- Run a specific gopls code action on the cursor position, applying it directly
-- when it is the only match instead of opening the generic code-action picker.
local function action(kind)
  return function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { kind }, diagnostics = {} },
    })
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- gopls publishes plenty of code lenses (run test, go generate, go mod tidy,
      -- govulncheck, upgrade dependency). LazyVim disables code lens rendering by
      -- default, so they stay invisible until this is turned on.
      opts.codelens = opts.codelens or {}
      opts.codelens.enabled = true

      local server = vim.tbl_get(opts, "servers", "gopls")
      local gopls = vim.tbl_get(opts, "servers", "gopls", "settings", "gopls")
      if not (server and gopls) then
        return
      end

      -- `useany` no longer exists in gopls; passing it makes gopls log an
      -- unknown-analyzer warning on every start. The rest of what LazyVim sets
      -- here is already the default in gopls >= 0.21, so it is harmless.
      gopls.analyses.useany = nil

      -- Off by default, and worth it: catches `err` shadowed inside an if/for
      -- block. Comment out if it turns out to be noisy on your codebases.
      gopls.analyses.shadow = true

      -- Surface vulnerable dependencies as diagnostics as you type, instead of
      -- only when you run the govulncheck code lens.
      gopls.vulncheck = "Imports"

      -- Completion, diagnostics and go-to-definition inside text/template files.
      gopls.templateExtensions = { "tmpl", "gotmpl", "gohtml" }

      -- Buffer-local; LazyVim attaches these only where gopls is running.
      -- The first four replace what gomodifytags / gotests / fillstruct used to
      -- do via none-ls — modern gopls does all of it natively.
      server.keys = {
        { "<leader>cgt", action("refactor.rewrite.addTags"), desc = "Add Struct Tags" },
        { "<leader>cgT", action("refactor.rewrite.removeTags"), desc = "Remove Struct Tags" },
        { "<leader>cgf", action("refactor.rewrite.fillStruct"), desc = "Fill Struct" },
        { "<leader>cga", action("source.addTest"), desc = "Add Test for Function" },
        { "<leader>cgn", action("refactor.extract.toNewFile"), desc = "Extract to New File" },
        { "<leader>cgd", action("source.doc"), desc = "Browse Documentation" },
        { "<leader>cgA", action("source.assembly"), desc = "Browse Assembly" },
      }
    end,
  },

  -- Name the <leader>cg group in which-key.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cg", group = "golang", icon = { icon = "󰟓 ", color = "cyan" } },
      },
    },
  },

  -- The lang extra installs go/gomod/gowork/gosum but not the template grammar.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "gotmpl" } },
  },

  -- Some repos build a *custom* golangci-lint binary with module plugins compiled
  -- in (`.custom-gcl.yml` + `golangci-lint custom`). Their `.golangci.yml` then
  -- references linters that only exist in that binary, so the stock Mason one
  -- fails with `plugin("<name>"): plugin "<name>" not found`. Prefer the
  -- project-local binary whenever the project declares one.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function()
      local lint = require("lint")
      local fallback = lint.linters.golangcilint.cmd
      local warned = {}

      lint.linters.golangcilint.cmd = function()
        local buf = vim.api.nvim_buf_get_name(0)
        local root = vim.fs.root(buf ~= "" and buf or assert(vim.uv.cwd()), ".custom-gcl.yml")
        if not root then
          return fallback
        end

        -- Matches LOCALBIN in the kubebuilder Makefile layout these repos use.
        local bin = root .. "/bin/golangci-lint"
        if vim.uv.fs_stat(bin) then
          return bin
        end

        if not warned[root] then
          warned[root] = true
          vim.notify(
            ("%s declares .custom-gcl.yml but %s is missing.\nRun `make golangci-lint` in that directory to build it.")
              :format(vim.fn.fnamemodify(root, ":~"), vim.fn.fnamemodify(bin, ":~")),
            vim.log.levels.WARN,
            { title = "nvim-lint" }
          )
        end
        return bin
      end
    end,
  },

  -- Test runner. `dap_go_enabled` is set by the lang extra; this adds the flags
  -- that make failures reproducible rather than flaky-by-default.
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-golang"] = {
          go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
          -- Uncomment if you use testify suites — makes suite methods show up
          -- as individual tests in the summary panel.
          -- testify_enabled = true,
        },
      },
    },
  },
}

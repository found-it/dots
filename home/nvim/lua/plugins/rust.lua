-- Rust: LazyVim's `lang.rust` extra is imported in config/lazy.lua. That extra owns
-- rustaceanvim (which drives rust-analyzer itself -- nvim-lspconfig's `rust_analyzer`
-- is explicitly disabled, so LSP settings for Rust go through `vim.g.rustaceanvim`,
-- not `opts.servers`), crates.nvim for Cargo.toml, the rust/ron grammars, codelldb
-- via Mason and the rustaceanvim neotest adapter (live, because `test.core` is
-- imported).
--
-- Deliberately *not* configured here, because something already covers it:
--   * clippy on save -- rustaceanvim rewrites `check.command` to clippy whenever
--     `cargo-clippy` is on PATH (config/server.lua), which rustup's toolchain
--     provides. Setting `check` here by hand would opt out of that.
--   * a conform formatter -- rust-analyzer proxies rustfmt over LSP formatting and
--     honours the project's rustfmt.toml and toolchain like `cargo fmt` does.
--   * code lens rendering -- lua/plugins/go.lua enables `opts.codelens` for every
--     server, so rust-analyzer's Run/Debug/Implementations lenses come along free
--     (<leader>cc runs the one under the cursor).
--   * cargo-nextest -- rustaceanvim switches neotest over to it automatically when
--     the binary exists; it is installed in modules/home/packages.nix.

--- `:RustLsp <args>` as a keymap rhs. `opts.bang = true` gives the "repeat the last
--- one" variant of runnables/testables instead of reopening the picker.
local function rustlsp(args, opts)
  return function()
    vim.cmd.RustLsp(vim.tbl_extend("force", vim.split(args, " "), opts or {}))
  end
end

return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        -- Replaces the extra's on_attach rather than wrapping it: the extra puts
        -- `RustLsp codeAction` on <leader>cR, and <leader>cR is the group prefix
        -- below. Both of its keymaps are re-created here (as <leader>cRa and
        -- <leader>dr), so nothing is lost.
        on_attach = function(_, bufnr)
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          -- Buffer-local, not a global which-key spec like the golang group in
          -- go.lua: <leader>cR is LazyVim's "Rename File" everywhere else, and a
          -- global group entry would mislabel it in every non-Rust buffer.
          require("which-key").add({
            { "<leader>cR", group = "rust", buffer = bufnr, icon = { icon = "󱘗 ", color = "orange" } },
          })

          -- rust-analyzer nests its code actions (a single "Extract into..." entry
          -- that fans out); the generic <leader>ca picker flattens that away.
          map("<leader>cRa", rustlsp("codeAction"), "Code Action (Rust)")

          -- Pickers over every runnable/testable in scope. The capitals skip the
          -- picker and re-run whatever was chosen last.
          map("<leader>cRr", rustlsp("runnables"), "Runnables")
          map("<leader>cRR", rustlsp("runnables", { bang = true }), "Runnables (Last)")
          map("<leader>cRt", rustlsp("testables"), "Testables")
          map("<leader>cRT", rustlsp("testables", { bang = true }), "Testables (Last)")
          map("<leader>dr", rustlsp("debuggables"), "Rust Debuggables")

          -- `explainError` pulls up the long-form `rustc --explain E0499` text;
          -- `renderDiagnostic` shows cargo's own ASCII-art rendering, which keeps
          -- the sub-spans that get flattened into one line in the diagnostic float.
          map("<leader>cRe", rustlsp("explainError current"), "Explain Error")
          map("<leader>cRE", rustlsp("renderDiagnostic current"), "Render Diagnostic")

          map("<leader>cRm", rustlsp("expandMacro"), "Expand Macro")
          map("<leader>cRp", rustlsp("parentModule"), "Parent Module")
          map("<leader>cRc", rustlsp("openCargo"), "Open Cargo.toml")
          map("<leader>cRd", rustlsp("openDocs"), "Open External Docs")
          map("<leader>cRj", rustlsp("joinLines"), "Join Lines", { "n", "v" })
          map("<leader>cRs", rustlsp("ssr"), "Structural Search Replace", { "n", "v" })
          map("<leader>cRv", rustlsp("view mir"), "View MIR")
          map("<leader>cRV", rustlsp("view hir"), "View HIR")

          -- Recovery hatches: flyCheck re-runs cargo check without a write (handy
          -- when a change in another crate invalidated the diagnostics here),
          -- reloadWorkspace after editing Cargo.toml outside the editor, and
          -- rebuildProcMacros after a proc-macro crate changed under you.
          map("<leader>cRf", rustlsp("flyCheck run"), "Fly Check")
          map("<leader>cRw", rustlsp("reloadWorkspace"), "Reload Workspace")
          map("<leader>cRb", rustlsp("rebuildProcMacros"), "Rebuild Proc Macros")

          -- LazyVim's <leader>cR ("Rename File") is disabled in Rust buffers below
          -- so this prefix is free; keep the action reachable.
          map("<leader>cRn", function()
            Snacks.rename.rename_file()
          end, "Rename File")
        end,

        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              -- rust-analyzer and a terminal `cargo build` otherwise contend for
              -- the same lock on target/, so each blocks the other for as long as
              -- the other takes. This gives the LSP its own target/rust-analyzer.
              -- Costs disk, saves the "waiting for cargo metadata" stalls.
              targetDir = true,
              -- NOTE: the extra sets `allFeatures = true`. Crates with mutually
              -- exclusive features (common in embedded -- you have thumbv7em std
              -- installed) will fail to analyse under it. Override per project in
              -- .vscode/settings.json, which rustaceanvim reads on attach.
            },
            -- Auto-imports: group by module and prefer `self::` paths, so inserted
            -- `use` lines match what rustfmt/`cargo fmt` would leave behind.
            imports = {
              granularity = { enforce = true, group = "module" },
              prefix = "self",
            },
            completion = {
              callable = { snippets = "fill_arguments" },
              fullFunctionSignatures = { enable = true },
            },
            inlayHints = {
              -- On by default and worth keeping: closure return types only where
              -- the body is a block, and lifetimes only where they are not the
              -- obvious single-input elision.
              closureReturnTypeHints = { enable = "with_block" },
              lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
              reborrowHints = { enable = "never" },
              -- `ref`/`mut` on every destructured binding is more noise than signal.
              bindingModeHints = { enable = false },
            },
            -- <leader>ss / <leader>sS also reach symbols in dependencies, which is
            -- how you find a trait method you only know by name.
            workspace = { symbol = { search = { kind = "all_symbols" } } },
          },
        },
      },
    },
  },

  -- Two of LazyVim's global LSP keymaps need adjusting for Rust. They are
  -- registered once from `servers["*"].keys` with a buffer filter (not per attach),
  -- so they cannot be overwritten from rustaceanvim's on_attach -- they have to be
  -- redefined here. Entries are resolved by lhs, so these replace the originals.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            -- Frees <leader>cR to be the Rust group prefix; without this every
            -- <leader>cR… sequence stalls for 'timeoutlen' first. Rust buffers get
            -- the same action back on <leader>cRn.
            {
              "<leader>cR",
              function()
                Snacks.rename.rename_file()
              end,
              desc = "Rename File",
              has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
              enabled = function(buf)
                return vim.bo[buf].filetype ~= "rust"
              end,
            },
            -- rustaceanvim's hover is the normal hover plus an actions list (go to
            -- impl/def, open docs) you reach by pressing K a second time. One
            -- mapping that branches, because a second `K` entry would just replace
            -- this one rather than coexist with it.
            {
              "K",
              function()
                if vim.bo.filetype == "rust" then
                  return vim.cmd.RustLsp({ "hover", "actions" })
                end
                return vim.lsp.buf.hover()
              end,
              desc = "Hover",
            },
          },
        },
      },
    },
  },

  -- Cargo.toml. The extra turns on crates.nvim's LSP (so <leader>ca offers
  -- "upgrade crate" and friends) but binds no keys and shows no popups.
  {
    "Saecki/crates.nvim",
    opts = {
      completion = {
        crates = {
          -- Query crates.io while typing a dependency name, not just versions of
          -- crates already written down.
          enabled = true,
          max_results = 12,
        },
      },
      popup = { autofocus = true },
      on_attach = function(bufnr)
        local crates = require("crates")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        require("which-key").add({
          { "<leader>cR", group = "rust", buffer = bufnr, icon = { icon = "󱘗 ", color = "orange" } },
        })

        -- upgrade = bump the requirement in Cargo.toml to the newest release;
        -- update = only move Cargo.lock inside the existing requirement.
        map("<leader>cRu", crates.upgrade_crate, "Upgrade Crate")
        map("<leader>cRU", crates.upgrade_all_crates, "Upgrade All Crates")
        map("<leader>cRl", crates.update_all_crates, "Update Lockfile")

        map("<leader>cRv", crates.show_versions_popup, "Show Versions")
        map("<leader>cRf", crates.show_features_popup, "Show Features")
        map("<leader>cRD", crates.show_dependencies_popup, "Show Dependencies")

        -- Turns `foo = "1.0"` into `foo = { version = "1.0" }` so features,
        -- default-features or a git source can be added to it.
        map("<leader>cRe", crates.expand_plain_crate_to_inline_table, "Expand to Inline Table")
        map("<leader>cRE", crates.extract_crate_into_table, "Extract into Table")

        map("<leader>cRd", crates.open_documentation, "Open docs.rs")
        map("<leader>cRc", crates.open_crates_io, "Open crates.io")
        map("<leader>cRr", crates.open_repository, "Open Repository")
        map("<leader>cRh", crates.open_homepage, "Open Homepage")
      end,
    },
  },
}

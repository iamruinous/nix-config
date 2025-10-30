-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      inlay_hints = true,
    },
    -- enable servers that you already have installed without mason
    servers = {
      "basedpyright",
      "biome",
      "golangci_lint_ls",
      "gopls",
      "harper_ls",
      "lemminx",
      "lua_ls",
      "marksman",
      "nil_ls",
      "ruff",
      "rust_analyzer",
      "taplo",
      "typos_lsp",
      "yamlls",
      "zls",
    },
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      --       golangci_lint_ls = {
      -- settings = {
      --
      --           go = {
      --
      --             k
      --           }
      --         },
      --       },
      nil_ls = {
        settings = {
          ["nil"] = {
            testSetting = 42,
            formatting = {
              command = { "alejandra" },
            },
          },
        },
      },
    },
  },
}

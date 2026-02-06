-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "n0frills",
    highlights = {
      init = function()
        return {
          CursorLine = { bg = "#3a3a3a" },
          CursorLineNr = { fg = "#d75fd7", bold = true },
          Visual = { bg = "#3a3a3a" },
          NormalFloat = { bg = "#1c1c1c" },
          FloatBorder = { fg = "#3a3a3a" },
          TelescopeBorder = { fg = "#3a3a3a" },
          TelescopePromptBorder = { fg = "#d75fd7" },
          TelescopeSelection = { bg = "#3a3a3a" },
          TelescopeMatching = { fg = "#5fd7d7", bold = true },
          DiagnosticError = { fg = "#ff5faf" },
          DiagnosticWarn = { fg = "#ffafd7" },
          DiagnosticInfo = { fg = "#5fd7d7" },
          DiagnosticHint = { fg = "#8a8a8a" },
          StatusLine = { fg = "#eeeeee", bg = "#3a3a3a" },
          StatusLineNC = { fg = "#626262", bg = "#3a3a3a" },
        }
      end,
    },
  },
}

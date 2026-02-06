local n0 = {
  bg = "#1c1c1c",
  fg = "#eeeeee",
  primary = "#d75fd7",
  accent = "#5fd7d7",
  hot = "#ff5faf",
  warn = "#ffafd7",
  gray = "#8a8a8a",
  muted = "#626262",
  dim = "#4e4e4e",
  border = "#3a3a3a",
}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "n0frills"

local set = vim.api.nvim_set_hl

-- Core UI
set(0, "Normal", { fg = n0.fg, bg = n0.bg })
set(0, "NormalNC", { fg = n0.fg, bg = n0.bg })
set(0, "NormalFloat", { fg = n0.fg, bg = n0.bg })
set(0, "FloatBorder", { fg = n0.border, bg = n0.bg })
set(0, "Visual", { bg = n0.border })
set(0, "CursorLine", { bg = n0.border })
set(0, "CursorLineNr", { fg = n0.primary, bg = n0.border, bold = true })
set(0, "LineNr", { fg = n0.muted, bg = n0.bg })
set(0, "SignColumn", { fg = n0.muted, bg = n0.bg })
set(0, "ColorColumn", { bg = n0.border })
set(0, "VertSplit", { fg = n0.border, bg = n0.bg })
set(0, "WinSeparator", { fg = n0.border, bg = n0.bg })
set(0, "StatusLine", { fg = n0.fg, bg = n0.border })
set(0, "StatusLineNC", { fg = n0.muted, bg = n0.border })
set(0, "Pmenu", { fg = n0.fg, bg = n0.bg })
set(0, "PmenuSel", { fg = n0.bg, bg = n0.primary, bold = true })
set(0, "PmenuSbar", { bg = n0.border })
set(0, "PmenuThumb", { bg = n0.dim })
set(0, "MatchParen", { fg = n0.accent, bg = n0.border, bold = true })
set(0, "Search", { fg = n0.bg, bg = n0.accent })
set(0, "IncSearch", { fg = n0.bg, bg = n0.primary })
set(0, "Title", { fg = n0.primary, bold = true })
set(0, "Directory", { fg = n0.accent })
set(0, "ErrorMsg", { fg = n0.hot, bg = n0.bg, bold = true })
set(0, "WarningMsg", { fg = n0.warn, bg = n0.bg, bold = true })

-- Syntax
set(0, "Comment", { fg = n0.muted, italic = true })
set(0, "Constant", { fg = n0.accent })
set(0, "String", { fg = n0.warn })
set(0, "Character", { fg = n0.warn })
set(0, "Number", { fg = n0.warn })
set(0, "Boolean", { fg = n0.warn })
set(0, "Identifier", { fg = n0.fg })
set(0, "Function", { fg = n0.accent })
set(0, "Statement", { fg = n0.primary })
set(0, "Keyword", { fg = n0.primary })
set(0, "Operator", { fg = n0.gray })
set(0, "Type", { fg = n0.accent })
set(0, "Special", { fg = n0.primary })

-- Diagnostics
set(0, "DiagnosticError", { fg = n0.hot })
set(0, "DiagnosticWarn", { fg = n0.warn })
set(0, "DiagnosticInfo", { fg = n0.accent })
set(0, "DiagnosticHint", { fg = n0.gray })
set(0, "DiagnosticUnderlineError", { undercurl = true, sp = n0.hot })
set(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = n0.warn })
set(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = n0.accent })
set(0, "DiagnosticUnderlineHint", { undercurl = true, sp = n0.gray })

-- Git signs
set(0, "DiffAdd", { fg = n0.accent, bg = n0.bg })
set(0, "DiffChange", { fg = n0.primary, bg = n0.bg })
set(0, "DiffDelete", { fg = n0.hot, bg = n0.bg })
set(0, "DiffText", { fg = n0.bg, bg = n0.primary })

-- Telescope
set(0, "TelescopeBorder", { fg = n0.border, bg = n0.bg })
set(0, "TelescopePromptBorder", { fg = n0.primary, bg = n0.bg })
set(0, "TelescopeSelection", { bg = n0.border })
set(0, "TelescopeMatching", { fg = n0.accent, bold = true })

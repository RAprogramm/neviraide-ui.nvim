local colors = require('neviraide-ui.themes').get_theme_tb('base_30')

local M = {
  NvimTreeWinSeparator = {
    fg = colors.one_bg2,
    bg = 'NONE',
  },
}

local hl_groups = {
  'Normal',
  'Folded',
  'NeoTreeNormal',
  'NeoTreeNormalNC',
  'NeoTreeEndOfBuffer',
  'NeoTreeWinSeparator',
  'NeoTreeStatusLine',
  'NeviraideDashboardAscii',
}

local hl_borderless = {
  'NormalFloat',
  'TelescopeNormal',
  'TelescopePrompt',
  'TelescopeResults',
  'TelescopeResultsTitle',
  'TelescopePromptNormal',
  'TelescopePromptPrefix',
  'CursorLine',
  'Pmenu',
  'CmpPmenu',
  'CmpDoc',
  'CmpDocBorder',
  'WhichKeyFloat',
}

for _, groups in ipairs(hl_groups) do
  M[groups] = {
    bg = 'NONE',
  }
end

if
  vim.g.borders == 'rounded'
  or vim.g.borders == 'single'
  or vim.g.borders == 'double'
then
  for _, groups in ipairs(hl_borderless) do
    M[groups] = {
      bg = 'none',
    }
  end
  M.TelescopeBorder = { fg = colors.grey, bg = 'NONE' }
  M.TelescopePromptBorder = { fg = colors.grey, bg = 'NONE' }
  M.CmpDocBorder = { bg = 'none', fg = colors.grey }
  M.TelescopeResultsTitle = {
    fg = colors.black,
    bg = colors.blue,
  }
end

return M

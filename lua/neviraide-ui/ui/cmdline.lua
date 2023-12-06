local require = require('neviraide-ui.utils.lazy')

local Message = require('neviraide-ui.message')
local Manager = require('neviraide-ui.message.manager')
local Config = require('neviraide-ui.config')
local NeviraideUIText = require('neviraide-ui.text')
local Hacks = require('neviraide-ui.utils.hacks')
local Object = require('nui.object')

local M = {}
M.message = Message('cmdline', nil)

---@enum CmdlineEvent
M.events = {
  cmdline = 'cmdline',
  show = 'cmdline_show',
  hide = 'cmdline_hide',
  pos = 'cmdline_pos',
  special_char = 'cmdline_special_char',
  block_show = 'cmdline_block_show',
  block_append = 'cmdline_block_append',
  block_hide = 'cmdline_block_hide',
}

---@type NeviraideUICmdline?
M.active = nil

---@alias NeviraideUICmdlineFormatter fun(cmdline: NeviraideUICmdline): {icon?:string, offset?:number, view?:NeviraideUIViewOptions}

---@class CmdlineState
---@field content {[1]: integer, [2]: string}[]
---@field pos number
---@field firstc string
---@field prompt string
---@field indent number
---@field level number
---@field block table

---@class CmdlineFormat
---@field kind string
---@field pattern? string|string[]
---@field view string
---@field conceal? boolean
---@field icon? string
---@field icon_hl_group? string
---@field opts? NeviraideUIViewOptions
---@field title? string
---@field lang? string

---@class NeviraideUICmdline
---@field state CmdlineState
---@field offset integer
---@overload fun(state:CmdlineState): NeviraideUICmdline
local Cmdline = Object('NeviraideUICmdline')

---@param state CmdlineState
function Cmdline:init(state)
  self.state = state or {}
  self.offset = 0
end

function Cmdline:get()
  return table.concat(
    vim.tbl_map(function(c) return c[2] end, self.state.content),
    ''
  )
end

---@return CmdlineFormat
function Cmdline:get_format()
  if self.state.prompt and self.state.prompt ~= '' then
    return Config.options.cmdline.format.input
  end
  local line = self.state.firstc .. self:get()

  ---@type {offset:number, format: CmdlineFormat}[]
  local ret = {}

  for _, format in pairs(Config.options.cmdline.format) do
    local patterns = type(format.pattern) == 'table' and format.pattern
      or { format.pattern }
    ---@cast patterns string[]
    for _, pattern in ipairs(patterns) do
      local from, to = line:find(pattern)
      -- if match and cmdline pos is visible
      if from and self.state.pos >= to - 1 then
        ret[#ret + 1] = {
          offset = to or 0,
          format = format,
        }
      end
    end
  end
  table.sort(ret, function(a, b) return a.offset > b.offset end)
  local format = ret[1]
  if format then
    self.offset = format.format.conceal and format.offset or 0
    return format.format
  end
  self.offset = 0
  return {
    kind = self.state.firstc,
    view = 'cmdline_popup',
  }
end

---@param message NeviraideUIMessage
---@param text_only? boolean
function Cmdline:format(message, text_only)
  local format = self:get_format()

  if format.icon then
    message:append(
      NeviraideUIText.virtual_text(format.icon, format.icon_hl_group)
    )
    message:append(' ')
  end

  if not text_only then message.kind = format.kind end

  -- FIXME: prompt
  if self.state.prompt ~= '' then
    message:append(self.state.prompt, 'NeviraideUICmdlinePrompt')
  end

  if not format.conceal then message:append(self.state.firstc) end

  local cmd = self:get():sub(self.offset)

  message:append(cmd)

  if format.lang then
    message:append(NeviraideUIText.syntax(format.lang, 1, -vim.fn.strlen(cmd)))
  end

  if not text_only then
    local cursor = NeviraideUIText.cursor(-self:length() + self.state.pos)
    cursor.on_render = M.on_render
    message:append(cursor)
  end
end

function Cmdline:width() return vim.api.nvim_strwidth(self:get()) end

function Cmdline:length() return vim.fn.strlen(self:get()) end

---@type NeviraideUICmdline[]
M.cmdlines = {}

function M.on_show(event, content, pos, firstc, prompt, indent, level)
  local c = Cmdline({
    event = event,
    content = content,
    pos = pos,
    firstc = firstc,
    prompt = prompt,
    indent = indent,
    level = level,
  })
  local last = M.cmdlines[level] and M.cmdlines[level].state
  if not vim.deep_equal(c.state, last) then
    M.active = c
    M.cmdlines[level] = c
    M.update()
  end
end

function M.on_hide(_, level)
  if M.cmdlines[level] then
    M.cmdlines[level] = nil
    local active = M.active
    vim.defer_fn(function()
      if M.active == active then M.active = nil end
    end, 100)
    M.update()
  end
end

function M.on_pos(_, pos, level)
  if M.cmdlines[level] and M.cmdlines[level].state.pos ~= pos then
    M.cmdlines[level].state.pos = pos
    M.update()
  end
end

---@class CmdlinePosition
---@field win number Window containing the cmdline
---@field buf number Buffer containing the cmdline
---@field bufpos {row:number, col:number} (1-0)-indexed position of the cmdline in the buffer
---@field screenpos {row:number, col:number} (1-0)-indexed screen position of the cmdline
M.position = nil

---@param buf number
---@param line number
---@param byte number
function M.on_render(_, buf, line, byte)
  Hacks.cmdline_force_redraw()
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    -- FIXME: check with cmp
    -- FIXME: state.pos?
    local cmdline_start = byte - (M.last():length() - M.last().offset)

    local cursor = byte - M.last():length() + M.last().state.pos
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_cursor(win, { 1, cursor })
        vim.api.nvim_win_call(win, function()
          local width = vim.api.nvim_win_get_width(win)
          local leftcol = math.max(cursor - width + 1, 0)
          vim.fn.winrestview({ leftcol = leftcol })
        end)
      end
    end)

    local pos = vim.fn.screenpos(win, line, cmdline_start)
    M.position = {
      buf = buf,
      win = win,
      bufpos = {
        row = line,
        col = cmdline_start,
      },
      screenpos = {
        row = pos.row,
        col = pos.col - 1,
      },
    }
  end
end

function M.last()
  local last = math.max(1, unpack(vim.tbl_keys(M.cmdlines)))
  return M.cmdlines[last]
end

function M.update()
  M.message:clear()
  local cmdline = M.last()

  if cmdline then
    cmdline:format(M.message)
    Hacks.hide_cursor()
    Manager.add(M.message)
  else
    Manager.remove(M.message)
    Hacks.show_cursor()
  end
end

return M

local require = require('neviraide-ui.utils.lazy')

local View = require('neviraide-ui.view')
local Manager = require('neviraide-ui.message.manager')
local Config = require('neviraide-ui.config')
local Util = require('neviraide-ui.utils')
local Message = require('neviraide-ui.message')
local Router = require('neviraide-ui.message.router')

---@class NeviraideUICommand: NeviraideUIRouteConfig
---@field filter_opts NeviraideUIMessageOpts

local M = {}

---@type table<string, fun()>
M.commands = {}

---@param command NeviraideUICommand
function M.command(command)
  return function()
    local view = View.get_view(command.view, command.opts)
    view:set(Manager.get(
      command.filter,
      vim.tbl_deep_extend('force', {
        history = true,
        sort = true,
      }, command.filter_opts or {})
    ))
    view:display()
  end
end

function M.cmd(cmd)
  if M.commands[cmd] then
    M.commands[cmd]()
  else
    M.commands.history()
  end
end

function M.setup()
  M.commands = {
    debug = function() Config.options.debug = not Config.options.debug end,
    dismiss = function() Router.dismiss() end,
    log = function() vim.cmd.edit(Config.options.log) end,
    enable = function() require('neviraide-ui').enable() end,
    disable = function() require('neviraide-ui').disable() end,
    stats = function() Manager.add(Util.stats.message()) end,
    routes = function()
      local message = Message('neviraide-ui', 'debug')
      message:set(vim.inspect(Config.options.routes))
      Manager.add(message)
    end,
    config = function()
      local message = Message('neviraide-ui', 'debug')
      message:set(vim.inspect(Config.options))
      Manager.add(message)
    end,
    viewstats = function()
      local message = Message('neviraide-ui', 'debug')
      message:set(
        vim.inspect(require('neviraide-ui.message.router').view_stats())
      )
      Manager.add(message)
    end,
  }

  for name, command in pairs(Config.options.commands) do
    M.commands[name] = M.command(command)
  end

  vim.api.nvim_create_user_command('NeviraideUI', function(args)
    local cmd = vim.trim(args.args or '')
    M.cmd(cmd)
  end, {
    nargs = '?',
    desc = 'NeviraideUI',
    complete = function(_, line)
      if line:match('^%s*NeviraideUI %w+ ') then return {} end
      local prefix = line:match('^%s*NeviraideUI (%w*)') or ''
      return vim.tbl_filter(
        function(key) return key:find(prefix) == 1 end,
        vim.tbl_keys(M.commands)
      )
    end,
  })

  for name in pairs(M.commands) do
    local cmd = 'NeviraideUI' .. name:sub(1, 1):upper() .. name:sub(2)
    vim.api.nvim_create_user_command(
      cmd,
      function() M.cmd(name) end,
      { desc = 'NeviraideUI ' .. name }
    )
  end
end

return M
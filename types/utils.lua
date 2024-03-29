---@class NeviraideUtils
---@field autocmd? fun(group: string, events: string | table, opts: table, clear?: boolean) Create autocommand. More information about |autocommands|
---@field autocmd_multi? fun(group: string , cmds:  table, clear?: boolean) Create multi autocommand. More information about |autocommands|
---@field has? fun(plugin: string): boolean Check if a plugin is configured.
---@field mason_path? function Add the mason bin directory to the PATH environment variable.
---@field icons? fun():table Set up nonicons or devicons.
---@field con? fun(plugin_name:string): function Plugin configuration.
---@field opt? fun(plugin_name:string): function Plugin options.
---@field on_very_lazy? fun(fn:function) Create autocmd very lazy.
---@field hi? fun(name: string, value: table) Set global highlights.
---@field term_toggle? fun(direction: string) Terminal direction.
---@field check_missing? fun(plugin: string, link?: string):function|table|nil Checks which plugin is missing.
---@field latest? fun():string|false Latest plugins versions.

---@param opts? NeviraideUIViewOptions
return function(opts)
  opts.type = 'popup'
  return require('neviraide-ui.view.nui')(opts)
end

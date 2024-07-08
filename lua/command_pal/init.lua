local M = {}

function M.setup(opts)
  require('command_pal.config').setup(opts)
  M.loaded = true
end

function M.open(opts)
  if not M.loaded then M.setup(opts) end
  opts = require('command_pal.config').merge_opts(opts or {})
  require('command_pal.palette').open_picker(opts)
end

M.open({})

return M

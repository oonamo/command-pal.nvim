local M = {}

function M.setup(opts)
  require('command_pal.config').setup(opts)
  M.loaded = true
end

---Opens Command Pal
---Merges the passed opts with your config.
---Config will be overwritten, and the passed opts will be prefered
---@param opts? CommandPalConfig
function M.open(opts)
  if not M.loaded then M.setup(opts) end
  opts = require('command_pal.config').merge_opts(opts or {})
  require('command_pal.palette').open_picker(opts)
end

M.open()

return M

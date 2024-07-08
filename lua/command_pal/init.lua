local M = {}

function M.setup(opts)
  M.__config = require('command_pal.config')
  M.__config:setup(opts)
  M.loaded = true
end

---Opens Command Pal
---Merges the passed opts with your config.
---Config will be overwritten, and the passed opts will be prefered
---If setup has not been called, open will set the config
---@param opts? CommandPalConfig
function M.open(opts)
  if not M.loaded then
    M.setup(opts)
    M.loaded = true
  end
  opts = M.__config:merge_opts(opts)
  M.__palette = M.__palette or require('command_pal.palette')
  M.__palette.open_picker(opts)
end

return M

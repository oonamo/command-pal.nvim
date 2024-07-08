local M = {}
local get_ordinal = require('command_pal.ordinal').get_ordinal
local default_handler = require('command_pal.handler').default_handler

---@param opts CommandPalConfig
---@return palette.MappedAction
function M.__map_overrides(opts)
  local overrides = opts.builtin.override() or {}
  for _, v in pairs(overrides) do
    if not v.cmd_str then
      if type(v.command) == 'string' then v.cmd_str = v.command end
    end
    v.ordinal = get_ordinal(v, opts)
    v.handler = v.handler or default_handler
  end
  return overrides
end

function M.get_items(opts) return M.__map_overrides(opts) end

return M

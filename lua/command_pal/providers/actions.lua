local get_ordinal = require('command_pal.ordinal').get_ordinal
local default_handler = require('command_pal.handler').default_handler

---@class provider.Actions : provider.Base
---@field __map_actions fun(opts: CommandPalConfig): palette.MappedAction
local M = {}

function M.__map_actions(opts)
  local actions = opts.actions
  for k, v in pairs(actions) do
    v.name = v.name or k
    v.desc = v.desc or ''
    v.group = v.group or opts.default_group
    v.ordinal = get_ordinal(v, opts)
    v.command = v.command or ''
    v.handler = v.handler or default_handler
  end
  return actions --[[@as palette.MappedAction]]
end

function M.get_items(opts) return M.__map_actions(opts) end

return M

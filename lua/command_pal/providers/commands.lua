local M = {
  group = 'User',
}

--- checks for ordinal = "desc" and the such
--- returs itself if it does not find key
--- if no oridnal is set, it uses the opts.search_for.priorities to
--- set value
---@param action builtin.Value
---@param opts CommandPalConfig
---
---@return string
local function get_ordinal(action, opts)
  if action.ordinal then
    for k, v in pairs(action) do
      if action.ordinal == k then action.ordinal = v end
    end
    return action.ordinal
  end

  for _, v in ipairs(opts.search_for.priorities) do
    if action[v] then return action[v] end
  end
  -- default to name

  return action.name
end

local function default_handler(v)
  if type(v.command) == 'string' then
    vim.cmd(v.command)
  elseif type(v.command) == 'function' then
    v.command()
  end
end

---@class commands.CommandT

---@param opts CommandPalConfig
---@return palette.MappedAction
function M.map_usercommands(opts)
  local usercommands = {}

  if vim.tbl_contains(opts.filter_group, M.group) then return usercommands end

  local command_i = vim.api.nvim_get_commands({})
  local set_cmd = require('command_pal.utils').set_cmdline
  for _, cmd in pairs(command_i) do
    usercommands[cmd.name] = {
      name = cmd.name,
      desc = cmd.definition,
      group = M.group,
      command = cmd.name,
      cmd_str = cmd.definition or '',
      ordinal = get_ordinal(cmd, opts),
      handler = (function()
        if cmd.nargs and cmd.nargs == '+' then return set_cmd(cmd.name .. ' ') end
        return default_handler
      end)(),
    }
  end
  return usercommands
end

return M

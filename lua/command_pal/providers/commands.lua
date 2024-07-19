---@class provider.Commands : provider.Base
---@field group string
---@field map_usercommands fun(opts): palette.MappedAction

---@class provider.Commands
local M = {
  group = 'User',
}

local get_ordinal = require('command_pal.ordinal').get_ordinal
local default_handler = require('command_pal.handler').default_handler
local set_cmd = require('command_pal.utils').set_cmdline

---@param opts CommandPalConfig
---@return palette.MappedAction
function M.map_usercommands(opts)
  local usercommands = {}
  local user_keys = require('command_pal.providers.keymaps').get_command_keymaps()

  if vim.tbl_contains(opts.filter_group, M.group) then return usercommands end

  local command_i = vim.api.nvim_get_commands({})
  for _, cmd in pairs(command_i) do
    local keymap = ''
    if user_keys[cmd.name] then keymap = user_keys[cmd.name].lhs end
    usercommands[cmd.name] = {
      name = cmd.name,
      desc = cmd.definition,
      group = M.group,
      command = cmd.name,
      keymap = keymap,
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

function M.get_items(opts) return M.map_usercommands(opts) end

return M

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local utils = require('command_pal.utils')
local config = require('command_pal.config').config

---@class palette.MappedAction
---@field name string
---@field keymap string
---@field handler fun(...): nil
---@field desc string
---@field ordinal string
---@field cmd_str string

---@class CommandPalette
---@field actions CommandPaletteItem[]
---@field opts table
---@field __mapped_actions palette.MappedAction[]

---@class CommandPalette

-- ---@tag command-pal.command-palette.specification
-- mod def
local M = {}

---@class CommandPaletteItem
---@field group string Group of command
---@field keymap? string keymap that launches command
---@field name string Name of command
---@field command string|fun(...): nil Command to be called on select
---@field desc? string Short Description of command

M.actions = {}

function M:__filter_group(filter)
  local newlist = {}
  for _, v in ipairs(self.__mapped_actions) do
    if v.group and not vim.tbl_contains(filter, v.group) then table.insert(newlist, v) end
  end
  return newlist
end
local function default_handler(v)
  if type(v.command) == 'string' then
    vim.cmd(v.command)
  elseif type(v.command) == 'function' then
    v.command()
  end
end

-- sort by search_priority
function M:__merge(...)
  self.__mapped_actions = self.__mapped_actions or {}
  local map = {}
  map = vim.tbl_deep_extend('force', map, ...)
  for k, v in pairs(map) do
    if not v.command_str and type(v.command) == 'string' then v.command_str = v.command end
    if not v.ordinal then v.ordinal = M.__get_ordinal(v) end
    if not v.handler then v.handler = default_handler end
    table.insert(self.__mapped_actions, {
      name = v.name or k,
      group = v.group,
      desc = v.desc,
      cmd_str = v.command_str,
      command = v.command,
      ordinal = v.ordinal,
      handler = v.handler,
    })
  end
end

---@param opts CommandPalConfig
function M.__command_displayer(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 0.2 },
      { width = 0.7 },
      { width = 10 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    return displayer({
      entry.name,
      { entry.desc, 'TelescopeResultsComment' },
      entry.cmd_str,
    })
  end

  return function(entry)
    return utils.make_entry.set_default_entry_mt({
      name = entry.name,
      handler = entry.handler,
      desc = entry.desc,
      definition = entry.definition,
      cmd_str = entry.cmd_str,
      --
      value = entry,
      ordinal = entry.ordinal,
      display = make_display,
    }, opts)
  end
end

function M:__merge_palette(opts)
  if not self.merged then
    local builtin = require('command_pal.providers.builtin'):__map_builtins(opts)
    local user = require('command_pal.providers.commands').map_usercommands(opts)
    local overrides = require('command_pal.providers.builtin'):__map_overrides(opts)
    self:__merge(builtin, user, overrides)
    self.merged = true
  end
end

---@param opts CommandPalConfig
function M.open_picker(opts)
  M:__merge_palette(opts)
  require('command_pal.pickers').picker_pick(
    opts,
    opts.filter_group ~= nil and M:__filter_group(opts.filter_group) or M.__mapped_actions
  )
end

return M

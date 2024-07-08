---@class palette.MappedAction
---@field name string
---@field keymap string
---@field handler fun(...): nil
---@field desc string
---@field ordinal string
---@field cmd_str string

---@class CommandPalette
---@field __mapped_actions palette.MappedAction[]

-- ---@tag command-pal.command-palette.specification
-- mod def
local M = {}

local utils = require('command_pal.utils')

---@class CommandPaletteItem
---@field group string Group of command
---@field keymap? string keymap that launches command
---@field name string Name of command
---@field command string|fun(...): nil Command to be called on select
---@field desc? string Short Description of command

M.actions = {}

---Filters the mapped actions by group
---@param filter string[]
---@return palette.MappedAction
function M:__filter_group(filter, items)
  local newlist = {}
  for _, v in ipairs(items) do
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

function M:__merge(...)
  local mapped_actions = {}
  local map = {}
  map = vim.tbl_deep_extend('force', map, ...)
  for k, v in pairs(map) do
    if not v.cmd_str and type(v.command) == 'string' then v.cmd_str = v.command end
    if not v.ordinal then v.ordinal = M.__get_ordinal(v) end
    if v.handler == nil then v.handler = default_handler end
    table.insert(mapped_actions, {
      name = v.name or k,
      group = v.group,
      desc = v.desc,
      cmd_str = v.cmd_str,
      command = v.command,
      ordinal = v.ordinal,
      handler = v.handler,
    })
  end
  return mapped_actions
end

---@param opts CommandPalConfig
function M:__merge_palette(opts) return self:__merge(unpack(require('command_pal.providers').get_palette_items(opts))) end

function M:get_palette(opts)
  self.__cache = self.__cache or {}
  local key = ''
  if opts == nil then
    key = 'nil'
  else
    key = utils.cache.serialize(opts)
  end
  if self.__cache[key] then return self.__cache[key] end

  local mapped_actions = self:__merge_palette(opts)
  self.__cache[key] = vim.deepcopy(mapped_actions)
  return mapped_actions
end

---@param opts CommandPalConfig
function M.open_picker(opts)
  local actions = M:get_palette(opts)
  require('command_pal.pickers').picker_pick(
    opts,
    opts.filter_group ~= nil and M:__filter_group(opts.filter_group, actions) or actions
  )
end

return M

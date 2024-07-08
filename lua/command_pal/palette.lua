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

function M:__merge(...)
  self.__mapped_actions = self.__mapped_actions or {}
  local map = {}
  map = vim.tbl_deep_extend('force', map, ...)
  for k, v in pairs(map) do
    if not v.cmd_str and type(v.command) == 'string' then v.cmd_str = v.command end
    if not v.ordinal then v.ordinal = M.__get_ordinal(v) end
    if not v.handler then v.handler = default_handler end
    table.insert(self.__mapped_actions, {
      name = v.name or k,
      group = v.group,
      desc = v.desc,
      cmd_str = v.cmd_str,
      command = v.command,
      ordinal = v.ordinal,
      handler = v.handler,
    })
  end
end

---@param opts CommandPalConfig
function M:__merge_palette(opts)
  if not self.merged then
    self:__merge(unpack(require('command_pal.providers').get_palette_items(opts)))
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

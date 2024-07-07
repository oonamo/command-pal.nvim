-- TODO: set actions as key = value pair, then merge instead of storing as array

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local utils = require('command_pal.utils')
local config = require('command_pal.config').config

---@class _MappedAction
---@field name string
---@field keymap string
---@field handler fun(...): nil
---@field desc string

---@class CommandPalette
---@field builtin table<BuiltinPaletteItem, ...>
---@field actions CommandPaletteItem[]
---@field opts table
---@field __mapped_actions _MappedAction[]

---@class BuiltinPaletteItem
---@field command fun()|string
---@field desc string

---@alias bt BuiltinPaletteItem

---@class Builtin
---@field w bt
---@field wa bt
---@field wa_bang bt
---@field q bt
---@field qa bt
---@field qa_bang bt
---@field colorscheme bt

---@class CommandPalette

---@tag command-pal.command-palette.specification
-- mod def
local M = {}

---@class CommandPaletteItem
---@field group string Group of command
---@field keymap? string keymap that launches command
---@field name string Name of command
---@field command string|fun(...): nil Command to be called on select
---@field desc? string Short Description of command

M.actions = {}

M.builtin = {
  w = { name = 'write', desc = 'Write the whole buffer to the current file.' },
  ['w!'] = { name = 'write force', desc = 'Forcefully Write the whole buffer to the current file.' },
  wq = { name = 'write quit', desc = 'Write the current file and close the window.' },
  ['wq!'] = { name = 'write quit force', desc = 'Write buffer and force quit' },
  wqa = { name = 'write quit all', desc = 'Write all buffers and quit' },
  ['wqa!'] = { name = 'write quit all force', desc = 'Write all buffers and fore quit' },
  q = { name = 'write quit', desc = 'Write buffer and Quit' },
  ['q!'] = { name = 'write quit force', desc = 'Write buffer and Quit' },
  qa = { name = 'write quit all', desc = 'Write all buffers and quit' },
  ['qa!'] = { name = 'write quit all', desc = 'Write all buffers and fore quit' },
  set = { name = 'Set option', desc = 'Toggle or vim set option', command = true },
  colorscheme = { name = 'Set colorscheme', desc = 'set colorscheme', command = true },
  nohighlights = { name = 'No highlight', desc = 'Remove highlights from search commands' },
  copen = { group = 'Quickfix', name = 'Quickfix Open', desc = 'open quickfix' },
  cclose = { group = 'Quickfix', name = 'Quickfix Close', desc = 'close quickfix' },
  cdo = {
    group = 'Quickfix',
    name = 'Quickfix Do',
    desc = 'run a command across all items in quickfix list',
    ordinal = 'desc',
    command = true,
  },
}

-- size of "Quickfix"
M.__largest_group_size = 8

---@alias builtinGroups
---| '"Vim"'
---| '"Quickfix"'

---@param disallow_list builtinGroups[]
function M:filter_builtins(disallow_list)
  local newlist = {}
  for k, v in pairs(self.builtin) do
    if v.group and not vim.tbl_contains(disallow_list, v.group) then newlist[k] = v end
  end
  self.builtin = newlist
end

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

function M.__get_ordinal(action, opts)
  if action.ordinal then
    for k, v in pairs(action) do
      if action.ordinal == k then action.ordinal = v end
    end
    return action.ordinal
  end
  if config.telescope.search_priority == nil then return action.name end
  for i, v in ipairs(config.telescope.search_priority) do
    if action[v] and v[i] ~= nil then return action[v] end
  end
  if config.telescope.fallback then return action[config.telescope.fallback] end
end

function M:__map_builtins()
  -- TODO: Move this to utilty folder
  local set_cmd = require('command_pal.utils').set_cmdline
  self.__mapped_actions = self.__mapped_actions or {}
  for k, v in pairs(self.builtin) do
    if v.group == nil then v.group = 'Vim' end
    if type(v.command) == 'boolean' and v.command == true then
      v.command = set_cmd(k .. ' ')
    else
      v.command = k
    end
    v.cmd_str = ''
    if type(v.command) == 'string' then v.cmd_str = v.command end
    v.handler = default_handler
    v.ordinal = M.__get_ordinal(v)
    table.insert(self.__mapped_actions, v)
  end
end

function M:__map_usercommands()
  local command_i = vim.api.nvim_get_commands({})
  self.__mapped_actions = self.__mapped_actions or {}
  local set_cmd = require('command_pal.utils').set_cmdline
  for _, cmd in pairs(command_i) do
    table.insert(self.__mapped_actions, {
      name = cmd.name,
      desc = cmd.definition,
      group = 'User',
      command = cmd.name,
      cmd_str = cmd.definition or '',
      ordinal = M.__get_ordinal(cmd),
      handler = (function()
        if cmd.nargs and cmd.nargs == '+' then return set_cmd(cmd.name .. ' ') end
        return default_handler
      end)(),
    })
  end
end

---@param item CommandPaletteItem
function M.new_item(item) table.insert(M.actions, item) end

function M:__map_actions()
  self.__mapped_actions = self.__mapped_actions or {}
  if config.actions == nil then return end
  for _, v in ipairs(config.actions) do
    if not v.group then
      v.group = 'Default'
    elseif #v.group > M.__largest_group_size then
      M.__largest_group_size = #v.group
    end
    v.command_str = ''
    if type(v.command) == 'string' then v.command_str = v.command end
    v.ordinal = M.__get_ordinal(v)
    table.insert(self.__mapped_actions, {
      name = v.name,
      group = v.group,
      desc = v.desc or '',
      cmd_str = v.command_str,
      ordinal = v.ordinal,
      handler = function()
        if type(v.command) == 'string' then vim.cmd(v.command) end
        if type(v.command) == 'function' then v.command() end
      end,
    })
  end
end

---@param opts PickerOpts
function M.__command_displayer(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = M.__largest_group_size + 1 },
      { width = 0.2 },
      { width = 0.7 },
      { width = 10 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    return displayer({
      { entry.group, 'TelescopeResultsIdentifier' },
      entry.name,
      { entry.desc, 'TelescopeResultsComment' },
      entry.cmd_str,
      -- entry.desc:gsub("\n", " "),
    })
  end

  return function(entry)
    -- local ordinal = entry.desc ~= "" and entry.desc or entry.name
    if opts.search_for then
      -- TODO: Validate ordinal
      -- ordinal = entry[opts.search_for]
      entry.ordinal = M.__get_ordinal(entry.ordinal)
    end
    return utils.make_entry.set_default_entry_mt({
      name = entry.name,
      handler = entry.handler,
      group = entry.group,
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

---@class PickerOpts
---@field search_for? Oridnals
---@field filter_group? table<string>

---@param opts PickerOpts
function M.open_picker(opts)
  if not M.merged then
    M:__map_actions()
    M:__map_builtins()
    M.merged = true
  end
  -- TODO: Autocommand to create new commands ?
  M:__map_usercommands()
  opts = opts or {}
  require('telescope.pickers')
    .new(opts, {
      prompt_title = 'Command Palette',
      finder = require('telescope.finders').new_table({
        results = opts.filter_group ~= nil and M:__filter_group(opts.filter_group) or M.__mapped_actions,
        entry_maker = M.__command_displayer(opts),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry().value
          entry:handler()
        end)
        return true
      end,
    })
    :find()
end

-- M.open_picker({
-- })
return M

local M = {}

---@class builtin.Value
---@field name string
---@field desc string
---@field bang? boolean
---@field command? boolean
---@field ordinal? string

---@class builtin.BuiltinT
---@field [string] builtin.Value

---@type builtin.BuiltinT
M.builtin = {
  w = { name = 'Write', desc = 'Write the whole buffer to the current file.' },
  ['w!'] = { name = 'Write Force', desc = 'Forcefully Write the whole buffer to the current file.', bang = true },
  wq = { name = 'Write Quit', desc = 'Write the current file and close the window.' },
  ['wq!'] = { name = 'Write Quit Force', desc = 'Write buffer and force quit', bang = true },
  wqa = { name = 'Write Quit All', desc = 'Write all buffers and quit' },
  ['wqa!'] = { name = 'Write Quit All force', desc = 'Write all buffers and fore quit', bang = true },
  q = { name = 'Write Quit', desc = 'Write buffer and quit' },
  ['q!'] = { name = 'Write Quit Force', desc = 'Write buffer and force quit', bang = true },
  qa = { name = 'Write Quit All', desc = 'Write all buffers and quit' },
  ['qa!'] = { name = 'Write Quit All', desc = 'Write all buffers and force quit', bang = true },
  set = { name = 'Set Option', desc = 'Toggle or vim set option', command = true },
  colorscheme = { name = 'Set Colorscheme', desc = 'Set Colorscheme', command = true },
  nohighlights = { name = 'No Highlight', desc = 'Remove highlights from search commands' },
  e = { name = 'Edit File', desc = 'If file exists, then edit file. Otherwise, create new file.', command = true },
  copen = { group = 'Quickfix', name = 'Quickfix Open', desc = 'Open quickfix buffer' },
  cclose = { group = 'Quickfix', name = 'Quickfix Close', desc = 'Close quickfix buffer' },
  cdo = {
    group = 'Quickfix',
    name = 'Quickfix Do',
    desc = 'run a command across all items in quickfix list',
    command = true,
  },
}

---@param v builtin.Value
local function default_handler(v)
  if type(v.command) == 'string' then
    vim.cmd(v.command)
  elseif type(v.command) == 'function' then
    v.command()
  end
end

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

---@param opts CommandPalConfig
---@return palette.MappedAction
function M:__map_builtins(opts)
  local set_cmd = require('command_pal.utils').set_cmdline
  local builtin = {}

  for k, v in pairs(self.builtin) do
    if not v.bang and opts.builtin.bang == false then
      if v.group == nil then v.group = 'Vim' end
      if type(v.command) == 'boolean' and v.command == true then
        v.command = set_cmd(k .. ' ')
      else
        v.command = k
      end
      v.cmd_str = ''
      if type(v.command) == 'string' then v.cmd_str = v.command end
      v.handler = default_handler
      v.ordinal = get_ordinal(v, opts)
      v.bang = nil
      builtin[k] = v
    end
  end

  return builtin
end

---@param opts CommandPalConfig
---@return palette.MappedAction
function M:__map_overrides(opts)
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

return M

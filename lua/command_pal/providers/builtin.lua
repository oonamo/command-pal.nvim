local get_ordinal = require('command_pal.ordinal').get_ordinal
local default_handler = require('command_pal.handler').default_handler
local set_cmd = require('command_pal.utils').set_cmdline

---@class provider.Builtin : provider.Base
---@field builtin builtin.BuiltinT
local M = {}

---@class builtin.Value
---@field name string
---@field desc string
---@field bang? boolean
---@field command? boolean
---@field ordinal? string

---@class builtin.BuiltinT
---@field [string] builtin.Value

M.builtin = {
  w = { name = 'Write', desc = 'Write the whole buffer to the current file.' },
  ['w!'] = { name = 'Write Force', desc = 'Forcefully Write the whole buffer to the current file.', bang = true },
  wq = { name = 'Write Quit', desc = 'Write the current file and close the window.' },
  ['wq!'] = { name = 'Write Quit Force', desc = 'Write buffer and force quit', bang = true },
  wqa = { name = 'Write Quit All', desc = 'Write all buffers and quit' },
  ['wqa!'] = { name = 'Write Quit All force', desc = 'Write all buffers and fore quit', bang = true },
  q = { name = 'Quit', desc = 'Quit the current buffer. If it is the last, exit nvim' },
  ['q!'] = { name = 'Quit Force', desc = 'Force Quit the current buffer, and exit nvim' },
  qa = { name = 'Quit All', desc = 'Quit all the buffers and leave if all quits were successful' },
  ['qa!'] = { name = 'Quit All Force', desc = 'Force Quit all buffers and leave nvim ' },
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
  help = { name = 'Open Help', desc = 'find help tag', command = true },
}

---@param opts CommandPalConfig
---@return palette.MappedAction
function M:__map_builtins(opts)
  local builtin = {}

  for k, v in pairs(self.builtin) do
    if not v.bang and opts.builtin.bang == false then
      builtin[k] = {
        name = v.name,
        group = v.group or 'Vim',
        desc = v.desc,
        command = (function()
          if type(v.command) == 'boolean' and v.command then
            return set_cmd(k .. ' ')
          else
            return k
          end
        end)(),
        cmd_str = k,
        handler = default_handler,
        ordinal = get_ordinal(v, opts),
      }
    end
  end

  return builtin
end

function M.get_items(opts) return M:__map_builtins(opts) end

return M

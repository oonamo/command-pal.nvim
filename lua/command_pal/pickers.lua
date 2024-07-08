local M = {
  picker_lookup = {
    'telescope',
    'mini_pick',
    'fzf-lua',
  },
}

---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.picker_pick(opts, results) require('command_pal.' .. opts.picker).pick(opts, results) end

return M

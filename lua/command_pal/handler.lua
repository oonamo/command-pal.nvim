local M = {}

function M.default_handler(v)
  if type(v.command) == 'string' then
    local ok, err = pcall(vim.cmd, v.command)
    if not ok then local set_cmd = require('command_pal.utils').set_cmdline(v.command .. " ")() end
    return 'vim cmd'
  elseif type(v.command) == 'function' then
    v.command()
    return 'custom command'
  end
end

return M

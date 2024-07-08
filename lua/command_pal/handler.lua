local M = {}

function M.default_handler(v)
  if type(v.command) == 'string' then
    vim.cmd(v.command)
    return 'vim cmd'
  elseif type(v.command) == 'function' then
    v.command()
    return 'custom command'
  end
end

return M

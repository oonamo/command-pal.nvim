-- local ok, minidoc = require("mini.doc")
local ok, minidoc = pcall(require, 'mini.doc')
if not ok then
  vim.notify("this file requires the 'mini.doc' to run correctly", vim.log.levels.WARN)
  return
end

if _G.MiniDoc == nil then minidoc.setup() end

local hooks = vim.deepcopy(MiniDoc.default_hooks)

hooks.write_pre = function(lines)
  -- Remove first two lines with `======` and `------` delimiters to comply
  -- with `:h local-additions` template
  table.remove(lines, 1)
  table.remove(lines, 1)
  return lines
end

local modules = {
  'utils',
  'config',
  -- 'command_palette'
  'palette',
}

for _, m in ipairs(modules) do
  vim.notify('generating for ' .. m)
  MiniDoc.generate({ 'lua/command_pal/' .. m .. '.lua' }, 'doc/command_pal-' .. m .. '.txt', { hooks = hooks })
end

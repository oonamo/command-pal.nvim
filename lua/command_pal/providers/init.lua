local M = {}

-- TODO: Make this the priority list
local providers = {
  'actions',
  'builtin',
  'commands',
  -- "help_tags",
  -- "keymaps",
  'overrides',
}

---@param opts CommandPalConfig
function M.get_palette_items(opts)
  local provider_items = {}
  for _, provider in ipairs(providers) do
    local items = require('command_pal.providers.' .. provider).get_items(opts)
    table.insert(provider_items, items)
  end
  return provider_items
end

return M

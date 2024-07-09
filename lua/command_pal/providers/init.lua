local M = {}

---@class provider.Base
---@field get_items fun(opts: CommandPalConfig): palette.MappedAction

-- TODO: Make this the priority list
local providers = {
  'actions',
  'builtin',
  'commands',
  -- "help_tags",
  -- "keymaps",
  'overrides',
}

local function get_spec_items(spec, opts)
  local ok, prov = pcall(require, spec)
  if ok then return prov.get_items(opts) end
  return {}
end

---@param opts CommandPalConfig
function M.get_palette_items(opts)
  local provider_items = {}
  for _, provider in ipairs(providers) do
    local items = {}
    if type(provider) == 'string' then
      items = require('command_pal.providers.' .. provider).get_items(opts)
    elseif type(provider) == 'table' then
      if provider.get_item and type(provider.get_item) == 'function' then
        items = provider.get_item(opts)
      elseif provider.spec then
        if type(provider.spec) == 'string' then
          items = get_spec_items(provider.spec, opts)
        elseif type(provider.spec) == 'function' then
          items = get_spec_items(provider.spec(), opts)
        end
      end
    end
    table.insert(provider_items, items or {})
  end
  return provider_items
end

return M

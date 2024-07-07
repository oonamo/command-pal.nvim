--- *command-pal* Show a Command Palette
--- *command_pal*
--- ==============================================================================
---
--- # Features
---   - Emacs' ivy style minibuffer
---   - Use builtin and custom commands. Easily override builtin commands
---     with |command_pal.filter_builtin()|

local H = {}
local M = {}
--- # Setup

---@alias Oridnals
---| "name"
---| "desc"

---@class CommandPalTelescopeOpts
---@field title string
---@field sorter? fun(any)
---@field opts table
---@field search_priority Oridnals[]
---@field fallback string

---@class BuiltinOpts
---@field filter builtinGroups[]
---@field override fun()

---@class CommandPalConfig
---@field actions CommandPaletteItem[]
---@field builtin BuiltinOpts
---@field telescope CommandPalTelescopeOpts
H.default = {
  telescope = {
    title = 'Command Palette',
    -- actually is require("telescope.conf").values.generic_sorter
    sorter = nil,
    opts = {},
    search_priority = {
      'name',
      'desc',
    },
    fallback = 'name',
  },
  actions = {},
  builtin = {
    filter = {},
    override = function() end,
  },
}

function M.setup(config)
  config = H.setup_config(config)
  M.config = config
end

function H.setup_config(config)
  vim.validate({
    config = {
      config,
      'table',
      true,
    },
  })

  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default), config or {})
  return config
end

return M

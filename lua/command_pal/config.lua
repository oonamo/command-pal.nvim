--- *command-pal.config* Show a Command Palette
--- *command_pal*
--- ==============================================================================
---
--- # Features
---   - Emacs' ivy style minibuffer
---   - Use builtin and custom commands. Easily override builtin commands
---     with |command_pal.filter_builtin()|
--- # Config
---
--- # Priorities
---

local H = {}
local M = {}
--- # Setup

---@alias config.Oridnals
---| "name"
---| "desc"

---@class config.SearchFor
---@field priorities string[]

---@class CommandPalTelescopeOpts
---@field title string
---@field sorter? fun(any)
---@field opts table
---@field fallback string
---@field keymaps table

---@class BuiltinOpts
---@field override fun()
---@field bang boolean

---@class config.UserAction
---@field name? string
---@field desc string
---@field group? string
---@field ordinal? string
---@field command? string

---@class config.UserActions
---@field [string] config.UserAction

---@class CommandPalConfig
---@field default_group string
---@field actions config.UserActions
---@field builtin BuiltinOpts
---@field telescope CommandPalTelescopeOpts
---@field search_for config.SearchFor
---@field filter_group string[]
---@field picker string

---@type CommandPalConfig
H.default = {
  default_group = 'UserAction',
  picker = 'telescope',
  search_for = {
    priorities = { 'name', 'command', 'desc', 'keymap' },
  },
  filter_group = {},
  telescope = {
    opts = {},
    title = 'Command Palette',
    -- actually is require("telescope.conf").values.generic_sorter
    sorter = nil,
    fallback = 'name',
    keymaps = {
      ['default'] = nil,
      ['<C-y>'] = nil,
    },
  },
  actions = {},
  builtin = {
    override = function() end,
    bang = false,
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

function M.merge_opts(opts)
  vim.validate({
    config = {
      opts,
      'table',
      true,
    },
  })

  opts = vim.tbl_deep_extend('force', M.config, opts or {})
  return opts
end

return M

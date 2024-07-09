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
---@field opts table
---@field ivy_style boolean

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

---@class config.MiniPick
---@field title string
---@field ivy_style boolean
---@field opts table

---@class CommandPalConfig
---@field default_group string
---@field actions config.UserActions
---@field builtin BuiltinOpts
---@field telescope CommandPalTelescopeOpts
---@field search_for config.SearchFor
---@field filter_group string[]
---@field picker string
---@field mini_pick config.MiniPick

---@type CommandPalConfig
H.default = {
  default_group = 'UserAction',
  picker = 'telescope',
  search_for = {
    priorities = { 'name', 'command', 'desc', 'keymap' },
  },
  filter_group = {},
  telescope = {
    ivy_style = true,
    opts = {},
  },
  mini_pick = {
    ivy_style = true,
    opts = {},
    title = 'Command Palette',
  },
  fzf_lua = {
    ivy_style = true,
    hide_nunber = false,
    opts = {},
  },
  actions = {},
  builtin = {
    override = function() end,
    bang = false,
  },
  providers = {
    'actions',
    'builtin',
    'commands',
    'overrides',
    {
      name = 'something',
      get_items = function(opts) end,
    },
    {
      spec = 'user.custom.my_special_actions',
    },
    -- TODO: How to do something like this?
    -- 'user.custom.my_special_actions'
  },
}

function M:setup(config)
  config = H.setup_config(config)
  self.config = config
end

function H.setup_config(config)
  config = vim.tbl_deep_extend('force', vim.deepcopy(H.default), config or {})
  return config
end

function M:merge_opts(opts)
  local new = vim.tbl_deep_extend('force', vim.deepcopy(self.config), opts or {})
  return new
end

return M

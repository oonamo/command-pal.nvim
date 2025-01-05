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

---@class config.PickerOpts
---@field ivy_style boolean
---@field show_command boolean
---@field show_key boolean
---@field opts table

local H = {}
local M = {}
--- # Setup

---@alias config.Oridnals
---| "name"
---| "desc"

---@class config.SearchFor
---@field priorities string[]

---@class CommandPalTelescopeOpts : config.PickerOpts

---@class BuiltinOpts
---@field override fun()
---@field bang boolean
---@field commands string[]

---@class config.UserAction
---@field name? string
---@field desc string
---@field group? string
---@field ordinal? string
---@field command? string

---@class config.UserActions
---@field [string] config.UserAction

---@class config.MiniPick : config.PickerOpts
---@field title string

---@class CommandPalConfig
---@field default_group string
---@field actions config.UserActions
---@field builtin BuiltinOpts
---@field telescope CommandPalTelescopeOpts
---@field search_for config.SearchFor
---@field filter_group string[]
---@field picker string
---@field mini_pick config.MiniPick
---@field max_command_len number

---@type CommandPalConfig
H.default = {
  default_group = 'UserAction',
  picker = 'telescope',
  max_command_len = 10,
  search_for = {
    priorities = { 'name', 'command', 'desc', 'keymap' },
  },
  filter_group = {},
  telescope = {
    ivy_style = true,
    show_command = true,
    show_key = true,
    opts = {},
  },
  mini_pick = {
    ivy_style = true,
    show_command = true,
    show_key = true,
    opts = {},
    title = 'Command Palette',
  },
  fzf_lua = {
    ivy_style = true,
    hide_nunber = false,
    show_command = true,
    show_key = true,
    opts = {},
  },
  actions = {},
  builtin = {
    override = function() end,
    bang = false,
    commands = {},
  },
  providers = {
    'actions',
    'builtin',
    'commands',
    'overrides',
    -- {
    --   name = 'something',
    --   get_items = function(opts) end,
    -- },
    -- {
    --   spec = 'user.custom.my_special_actions',
    -- },
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

---@class provider.Keymaps : provider.Base

---@class provider.Keymaps
---@field cache table
local M = {}

function M.get_keymaps() return vim.api.nvim_get_keymap('') end

function M.get_command_keymaps()
  local cmd_map = {}
  for _, v in ipairs(M.get_keymaps()) do
    if v.rhs then
      local cmd = v.rhs:match('<Cmd>(%w+)')
      if cmd and cmd ~= 'lua' then
        local maps_first_char = v.lhs:sub(1, 1)
        local lhs = ''
        if maps_first_char == vim.g.mapleader then
          lhs = '<leader>' .. v.lhs:sub(2, -1)
        elseif maps_first_char == vim.g.maplocalleader then
          lhs = '<localleader>' .. v.lhs:sub(2, -1)
        else
          lhs = v.lhs
        end
        if cmd_map[cmd] then
          cmd_map[cmd].lhs = cmd_map[cmd].lhs .. ', ' .. lhs
        else
          cmd_map[cmd] = { cmd = cmd, lhs = lhs }
        end
      end
    end
  end
  return cmd_map
end

---@param opts CommandPalConfig
---@return palette.MappedAction
function M.get_items(opts) return {} end

return M

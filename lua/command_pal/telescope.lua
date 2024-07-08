local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local utils = require('command_pal.utils')
local previewers = require('telescope.previewers')
local M = {}

---@param opts CommandPalConfig
function M.__command_displayer(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = 0.2 },
      { width = 0.7 },
      { width = 10 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    return displayer({
      entry.name,
      { entry.desc, 'TelescopeResultsComment' },
      entry.cmd_str,
    })
  end

  return function(entry)
    return utils.make_entry.set_default_entry_mt({
      name = entry.name,
      handler = entry.handler,
      desc = entry.desc,
      definition = entry.definition,
      cmd_str = entry.cmd_str,
      --
      value = entry,
      ordinal = entry.ordinal,
      display = make_display,
    }, opts)
  end
end

---Picks using Telescope
---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.pick(opts, results)
  require('telescope.pickers')
    .new(opts.telescope.opts, {
      prompt_title = 'Command Palette',
      finder = require('telescope.finders').new_table({
        results = results,
        entry_maker = M.__command_displayer(opts),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewers.new_buffer_previewer({
        title = 'Command Preview',
        dyn_title = function(_, entry) return entry.group end,
        define_preview = function(self, entry)
          if self.state.last_set_bufnr then
            pcall(vim.api.nvim_buf_clear_namespace, self.state.last_set_bufnr, M.ns_previewer, 0, -1)
          end
          local display = {}
          for k, v in pairs(entry) do
            if k ~= 'value' and k ~= 'ordinal' and k ~= 'index' and k ~= 'display' then
              table.insert(display, k .. ': ' .. tostring(v))
            end
          end
          -- vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'vim')
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display)
          -- vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, 'TelescopeBorder', 0, 0, -1)
          -- vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, 'TelescopePreviewLine', 0 + 1, 0, -1)
          self.state.last_set_bufnr = self.state.bufnr
        end,
      }),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry().value
          entry:handler()
          -- vim.notify(entry.handler(entry))
        end)
        return true
      end,
    })
    :find()
end

return M

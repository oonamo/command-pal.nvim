local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local utils = require('command_pal.utils')
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
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry().value
          entry:handler()
        end)
        return true
      end,
    })
    :find()
end

return M

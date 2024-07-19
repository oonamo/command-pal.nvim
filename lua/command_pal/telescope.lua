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
      { width = 0.8 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local col1 = entry.name
    local name_hl = {}
    -- TODO: Do the same for commands mapped to a keymap
    if entry.cmd_str and #entry.cmd_str < opts.max_command_len and opts.telescope.show_command then
      local hl_start = #entry.name + 1
      local hl_end = hl_start + #entry.cmd_str + 2
      table.insert(name_hl, { { hl_start, hl_end }, 'TelescopeResultsFunction' })
      col1 = col1 .. ' <' .. entry.cmd_str .. '>'
    end

    local res, hls = displayer({
      col1,
      { entry.desc, 'TelescopeResultsComment' },
    })

    if name_hl[1] ~= nil then table.insert(hls, name_hl[1]) end
    return res, hls
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

local function get_ivy_theme()
  return require('telescope.themes').get_ivy({
    layout_config = { height = 0.3 },
    preview = {
      hide_on_startup = true,
    },
  })
end

---@param opts CommandPalConfig
local function telescope_opts(opts) return vim.tbl_deep_extend('force', opts.telescope.opts, get_ivy_theme()) end

---Picks using Telescope
---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.pick(opts, results)
  require('telescope.pickers')
    .new(telescope_opts(opts), {
      prompt_title = opts.telescope.opts.prompt_title or 'Command Palette',
      finder = require('telescope.finders').new_table({
        results = results,
        entry_maker = M.__command_displayer(opts),
      }),
      sorter = opts.telescope.opts.sorter or conf.generic_sorter(opts),
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
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display)
          self.state.last_set_bufnr = self.state.bufnr
        end,
      }),
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

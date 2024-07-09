local M = {}

local has_fzflua, fzf = pcall(require, 'fzf-lua')
local builtin = require('fzf-lua.previewer.builtin')
local utils = require('command_pal.utils')
local futils = require('fzf-lua').utils

local function pad_str(str)
  str = str or ''
  for _ = 0, (M.padding - #str) do
    str = str .. ' '
  end
  return str
end

local function entry_display(opts)
  local max_width = vim.o.columns - 4
  local compiled_width = {}
  local total = 0

  for i, v in ipairs(opts.items) do
    if v.width < 1 then
      local result = math.floor(v.width * max_width)
      total = total + result
      compiled_width[i] = result
    else
      local result = math.floor(v.width)
      total = total + result
      compiled_width[i] = result
    end
  end
  compiled_width[#compiled_width + 1] = max_width - total

  return function(entry)
    local comp_str = ''
    for i, v in ipairs(compiled_width) do
      comp_str = comp_str .. pad_str(entry[i], v) .. (opts.separator or ' ')
    end
    return comp_str
  end
end

local displayer = entry_display({
  items = {
    { width = 0.2 },
    { width = 0.6 },
    { width = 10 },
  },
})

local function format_item(item)
  return displayer({
    item.name,
    item.desc,
    item.cmd_str,
  })
end

function M:get_action_from_name(entry)
  if entry == nil then return end
  local str_index = string.match(entry[1], '(.*):')
  if str_index == nil then return end
  local index = tonumber(str_index)
  if index == nil then return end
  return self.entries[index]
end

local display_lines = {
  'desc',
  'name',
  'group',
  'cmd_str',
}

local command_previewer = builtin.base:extend()

function command_previewer:new(o, opts, fzf_win)
  command_previewer.super.new(self, o, opts, fzf_win)
  setmetatable(self, command_previewer)
  return self
end

function command_previewer:populate_preview_buf(entry_str)
  local tmp_buf = self:get_tmp_buffer()
  local item = M:get_action_from_name({ entry_str })
  local display = {}
  for _, v in ipairs(display_lines) do
    if item[v] then table.insert(display, v .. ': ' .. item[v]) end
  end
  vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, display)
  self:set_preview_buf(tmp_buf)
  self.win:update_scrollbar()
end

-- Disable line numbering and word wrap
function command_previewer:gen_winopts()
  local new_winopts = {
    wrap = false,
    number = false,
  }
  return vim.tbl_extend('force', self.winopts, new_winopts)
end

local function get_inverse_hl()
  local fzf_norm = vim.api.nvim_get_hl(0, {
    name = 'FzfLuaNormal',
  })
  local fzf_bg = fzf_norm.bg
  vim.api.nvim_set_hl(0, 'CommandPalNormalHideFzf', { fg = fzf_bg, bg = fzf_bg })
end

get_inverse_hl()
local _, _, f = futils.ansi_from_hl('CommandPalNormalHideFzf')

local function transparent(str)
  -- if str == nil or #str == 0 then return '' end
  return f(str)
end

local function get_contents(fzf_cb)
  coroutine.wrap(function()
    local co = coroutine.running()
    for i, v in ipairs(M.entries) do
      fzf_cb(
        transparent(pad_str(tostring(i) .. ':')) .. futils.ansi_codes.magenta(v.name),
        function() coroutine.resume(co) end
      )
      coroutine.yield()
    end
    fzf_cb()
  end)()
end

function M.pick(opts, results)
  M.entries = results
  local count = #results
  M.padding = utils.get_digit_len(count)
  fzf.fzf_exec(get_contents, {
    previewer = command_previewer,
    fn_selected = function(selected, _)
      local item = M:get_action_from_name(selected)
      if item then item:handler() end
    end,
    fzf_opts = {
      ['--layout'] = 'reverse',
      ['--info'] = 'inline-right',
    },
    winopts_fn = function()
      return {
        width = 1,
        height = 0.30,
        row = 1,
        preview = {
          border = 'border',
          wrap = 'nowrap',
          hidden = 'nohidden',
          vertical = 'down:45%',
          horizontal = 'right:30%',
          layout = 'horizontal',
          title = true,
          title_align = 'center',
          scrollbar = 'float',
          scrolloff = '-2',
          scrollchars = { '█', '' },
          delay = 100,
          winopts = {
            number = true,
            relativenumber = false,
            cursorline = true,
            cursorlineopt = 'both',
            cursorcolumn = false,
            signcolumn = 'no',
            list = false,
            foldenable = false,
            foldmethod = 'manual',
          },
        },
      }
    end,
  })
end

return M

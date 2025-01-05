local M = {}
local utils = require('command_pal.utils')

---@class mini_pick.Helper
---@field compiled_width table<number>
local H = {}

H.opts = {
  items = {
    { width = 0.3 },
    { width = 0.7 },
    { width = 10, remaining = true },
  },
  order = {
    'text',
    'keymap',
  },
}

H.ids = {
  keymap = vim.api.nvim_create_namespace('command_pal_keymap'),
  desc = vim.api.nvim_create_namespace('command_pal_desc'),
}

local _, minipick = pcall(require, 'mini.pick')

vim.api.nvim_create_autocmd('VimResized', {
  callback = function() H.compiled_width = H.calculate_widths(H.opts) end,
})

function H.calculate_widths(opts)
  H.width = 0
  if M.ivy then
    H.width = vim.o.columns
  else
    H.width = minipick.config.window.height or math.floor(vim.o.columns * 0.618)
  end
  local total = 0
  local compiled_width = {}
  for i, v in ipairs(opts.items) do
    if v.width < 1 then
      local result = math.floor(v.width * H.width)
      total = total + result
      compiled_width[i] = result
    else
      local result = math.floor(v.width)
      total = total + result
      compiled_width[i] = result
    end
  end
  if opts.items[#opts.items].remaining then compiled_width[#compiled_width] = (H.width or vim.o.columns) - total end
  return compiled_width
end

local function pad_str(str, len)
  if str and #str > len then return str:sub(0, len - 2) .. '...' end
  str = str or ''
  for _ = 0, (len - #str) do
    str = str .. ' '
  end
  return str
end

local display_lines = {
  'name',
  'desc',
  'cmd_str',
}

local function previewer(buf_id, item)
  local display = {}
  for _, v in ipairs(display_lines) do
    if item[v] then table.insert(display, v .. ': ' .. item[v]) end
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, display)
end

-- TODO: mini.pick is fast, but would a cache be need at a certain size?
local function entry_display(opts)
  H.compiled_width = H.calculate_widths(opts)
  return function(entry)
    local comp_str = ''
    for i, v in ipairs(H.compiled_width) do
      if entry[i] then comp_str = comp_str .. pad_str(entry[i], v) .. (opts.separator or ' ') end
    end
    return {
      text = entry.command or entry.name or entry.command or entry.cmd_str,
      -- text = comp_str,
      keymap = entry.keymap,
      name = entry.name,
      handler = entry.handler,
      command = entry.command,
      desc = entry.desc,
      cmd_str = entry.cmd_str,
    }
  end
end

local displayer = entry_display(H.opts)

local function format_item(item)
  local col1 = item.name
  if item.keymap and item.keymap ~= '' and M.opts.mini_pick.show_key then
    col1 = col1 .. ' (' .. item.keymap .. ')'
  elseif
    item.cmd_str
    and item.cmd_str ~= ''
    and #item.cmd_str < M.opts.max_command_len
    and M.opts.mini_pick.show_command
  then
    col1 = col1 .. ' (' .. item.cmd_str .. ')'
  end
  return displayer({
    col1,
    -- item.name,
    item.desc,
    -- item.cmd_str,
    name = item.name,
    keymap = item.keymap,
    desc = item.desc,
    handler = item.handler,
    command = item.command,
    cmd_str = item.cmd_str,
    item = item,
  })
end

local function get_items(results)
  local items = {}
  for k, v in pairs(results) do
    items[k] = format_item(v)
  end
  -- vim.print(items)
  return items
end

local function get_ivy_theme()
  if M.ivy then
    return {
      config = {
        width = vim.o.columns,
        height = math.floor(vim.o.lines * 0.3),
      },
    }
  end
  return {}
end

local function get_minipick_win_opts()
  local ivy = get_ivy_theme()
  return vim.tbl_deep_extend('force', M.opts.mini_pick.opts, ivy)
end

local function show_keymap(buf_id, items, query, pos, line, i)
  if not items[line] then return end
  if items[line].keymap and items[line].keymap ~= '' and M.opts.mini_pick.show_key then
    local width = H.compiled_width[i] - #items[line].keymap
    local text = { { pad_str('(' .. items[line].keymap .. ')', width), 'Constant' } }
    vim.api.nvim_buf_set_extmark(buf_id, H.ids.keymap, line - 1, 0, {
      virt_text = text,
      virt_text_win_col = pos,
      hl_mode = 'combine',
    })
  end
end

local function show(buf_id, items, query)
  vim.api.nvim_buf_clear_namespace(buf_id, H.ids.keymap, 0, -1)
  require('mini.pick').default_show(buf_id, items, query, { show_icons = false })
  for line, item in ipairs(items) do
    local width = 0
    if item.text and type(item.text) == 'string' then
      local text_width = #item.text
      show_keymap(buf_id, items, query, text_width + 2, line, 1)
    end
    -- for i = 1, #H.opts.items do
    --   width = width + (M._cache.compiled_width[i - 1] or 0)
    --   if H[H.opts.order[i]] then H[H.opts.order[i]](buf_id, items, query, width, line, i) end
    -- end
  end
end

---Picks using MiniNvim
---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.pick(opts, results)
  M.opts = opts
  M.ivy = true
  if opts.mini_pick.ivy_style == false then M.ivy = false end
  minipick.start({
    source = {
      name = opts.mini_pick.title,
      items = get_items(results),
      show = show,
      choose = function(item)
        -- FIXME: might be better to use pick's api for making sure the window is closed
        vim.schedule(function() item:handler() end)
      end,
      preview = previewer,
    },
    window = get_minipick_win_opts(),
  })
end

return M

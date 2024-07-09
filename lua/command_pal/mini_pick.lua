local M = {}

local _, minipick = pcall(require, 'mini.pick')

local function pad_str(str, len)
  str = str or ''
  for _ = 0, (len - #str) do
    str = str .. ' '
  end
  return str
end

local display_lines = {
  'desc',
  'name',
  'group',
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
  local width = 0
  if M.ivy then
    width = vim.o.columns
  else
    width = minipick.config.window.height or math.floor(vim.o.columns * 0.618)
  end
  local compiled_width = {}
  local total = 0

  for i, v in ipairs(opts.items) do
    if v.width < 1 then
      local result = math.floor(v.width * width)
      total = total + result
      compiled_width[i] = result
    else
      local result = math.floor(v.width)
      total = total + result
      compiled_width[i] = result
    end
  end

  compiled_width[#compiled_width + 1] = (width or vim.o.columns) - total

  return function(entry)
    local comp_str = ''
    for i, v in ipairs(compiled_width) do
      comp_str = comp_str .. pad_str(entry[i], v) .. (opts.separator or ' ')
    end
    return {
      text = comp_str,
      name = entry.name,
      handler = entry.handler,
      command = entry.command,
      desc = entry.desc,
      cmd_str = entry.cmd_str,
    }
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
    name = item.name,
    desc = item.desc,
    handler = item.handler,
    command = item.command,
    cmd_str = item.cmd_str,
    item = item,
  })
end

local function get_items(results)
  local items = {}
  items = vim.tbl_map(format_item, results)
  return items
end

---@param opts CommandPalConfig
local function get_ivy_theme(opts)
  if opts.mini_pick then
    return {
      config = {
        width = vim.o.columns,
        height = math.floor(vim.o.lines * 0.3),
      },
    }
  end
  return {}
end

---@param opts CommandPalConfig
local function get_minipick_win_opts(opts)
  local ivy = get_ivy_theme(opts)
  return vim.tbl_deep_extend('force', opts.mini_pick.opts, ivy)
end

---Picks using MiniNvim
---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.pick(opts, results)
  if opts.mini_pick.ivy_style then
    M.ivy = true
  else
    -- M.max_width = require('mini.pick').config.window.height or math.floor(vim.o.columns * 0.618)
  end

  vim.print(M)
  minipick.start({
    source = {
      name = opts.mini_pick.title,
      items = get_items(results),
      choose = function(item)
        vim.schedule(function() item:handler() end)
      end,
      preview = previewer,
    },
    window = get_minipick_win_opts(opts),
  })
end

return M

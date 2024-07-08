local M = {}

local _, minipick = pcall(require, 'mini.pick')

local function pad_str(str, len)
  str = str or ''
  for _ = 0, (len - #str) do
    str = str .. ' '
  end
  return str
end

-- TODO: mini.pick is fast, but would a cache be need at a certain size?
local function entry_display(opts)
  local max_width = vim.o.columns
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
    return { text = comp_str, handler = entry.handler, command = entry.command }
  end
end

local displayer = entry_display({
  items = {
    { width = 0.2 },
    { width = 0.7 },
    { width = 10 },
  },
})

local function format_item(item)
  return displayer({
    item.name,
    item.desc,
    item.cmd_str,
    name = item.name,
    handler = item.handler,
    command = item.command,
  })
end

local function get_items(results)
  local items = {}
  items = vim.tbl_map(format_item, results)
  return items
end
-- if not has_pick then vim.notify('Command-pal picker mini.pick is not available') end

---Picks using MiniNvim
---@param opts CommandPalConfig
---@param results palette.MappedAction
function M.pick(opts, results)
  minipick.start({
    source = {
      name = opts.telescope.title,
      items = get_items(results),
      choose = function(item)
        vim.schedule(function() item:handler() end)
      end,
    },
    window = {
      config = {
        width = vim.o.columns,
      },
    },
  })
end

return M

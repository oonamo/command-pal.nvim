---@class Utils
---@field set_cmdline fun(key: string): fun() Sets commandline to key if the returned function is called
local M = {}

function M.set_cmdline(key)
  return function()
    if key:sub(1, 1) ~= ':' then key = ':' .. key end
    vim.api.nvim_input(vim.api.nvim_replace_termcodes(key, true, true, true))
  end
end

--- HACK: Copy code from Tel;escope to not require unneeded modules
--- FROM: https://github.com/nvim-telescope/telescope.nvim/blob/bfcc7d5c6f12209139f175e6123a7b7de6d9c18a/lua/telescope/make_entry.lua
local handle_entry_index = function(opts, t, k)
  local override = ((opts or {}).entry_index or {})[k]
  if not override then return end

  local val, save = override(t, opts)
  if save then rawset(t, k, val) end
  return val
end

M.make_entry = {}

function M.make_entry.set_default_entry_mt(tbl, opts)
  return setmetatable({}, {
    __index = function(t, k)
      local override = handle_entry_index(opts, t, k)
      if override then return override end

      -- Only hit tbl once
      local val = tbl[k]
      if val then rawset(t, k, val) end

      return val
    end,
  })
end

M.cache = {}

function M.cache.serialize(tbl)
  local serialized = ''
  for k, v in pairs(tbl) do
    serialized = serialized .. tostring(k)
    if type(v) == 'function' then
      serialized = serialized .. ':function'
    elseif type(v) == 'table' then
      serialized = serialized .. ':' .. M.cache.serialize(v)
    else
      serialized = serialized .. ':' .. tostring(v)
    end
  end
  return serialized
end

function M.defaulter(f, default_opts, conf)
  default_opts = default_opts or {}
  return {
    new = function(opts)
      if conf.preview == false and not opts.preview then return false end
      opts.preview = type(opts.preview) ~= 'table' and {} or opts.preview
      if type(conf.preview) == 'table' then
        for k, v in pairs(conf.preview) do
          opts.preview[k] = vim.F.if_nil(opts.preview[k], v)
        end
      end
      return f(opts)
    end,
    __call = function()
      local ok, err = pcall(f(default_opts))
      if not ok then error(debug.traceback(err)) end
    end,
  }
end
return M

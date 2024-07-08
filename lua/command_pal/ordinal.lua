local M = {}
function M.verify_ordinal(ord) end

--- checks for ordinal = "desc" and the such
--- returs itself if it does not find key
--- if no oridnal is set, it uses the opts.search_for.priorities to
--- set value
---@param action builtin.Value
---@param opts CommandPalConfig
---
---@return string
function M.get_ordinal(action, opts)
  if action.ordinal then
    for k, v in pairs(action) do
      if action.ordinal == k then action.ordinal = v end
    end
    return action.ordinal
  end

  for _, v in ipairs(opts.search_for.priorities) do
    if action[v] then return action[v] end
  end
  -- default to name

  return action.name
end

return M

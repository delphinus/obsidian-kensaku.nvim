local Job = require "plenary.job"

local filters = {}

---@param query string
---@return string
filters.kensaku = function(query)
  return vim.fn["kensaku#query"](query, { rxop = vim.g["kensaku#rxop#javascript"] })
end

---@param query string
---@return string
filters.cmigemo = function(query)
  local config = require "obsidian-kensaku.config"
  local result, code =
    Job:new({ command = config.cmigemo_executable, args = { "-w", query, "-d", config.migemo_dict_path } }):sync()
  return code == 0 and result and result[1] or query
end

return filters

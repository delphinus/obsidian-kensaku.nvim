local filters = {}

---@param query string
---@return string
filters.default = function(query)
  local config = require "obsidian-kensaku.config"
  local migemo = require "luamigemo"
  return migemo.get(config.dict_path):query(query)
end

return filters

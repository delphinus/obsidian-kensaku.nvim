local filters = {}

---@param query string
---@return string
filters.default = function(query)
  local config = require "obsidian-kensaku.config"
  local migemo = require "luamigemo"
  return migemo.query(config.dict_path, query, migemo.RXOP_PCRE)
end

return filters

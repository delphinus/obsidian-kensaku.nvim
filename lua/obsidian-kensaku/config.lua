local filters = require "obsidian-kensaku.filters"

---@class obsidian-kensaku.config.SetupOpts
---@field dict_path? string Path to migemo-compact-dict file. Uses luamigemo's bundled dictionary if not specified.
---@field picker? "default"|"egrepify" default: "default"
---@field previewer? fun(): table function that returns a telescope previewer
---@field query_filter? fun(query: string): string Custom filter function for grep (PCRE regex). Overrides built-in migemo.

---@class obsidian-kensaku.config
---@field dict_path? string
---@field picker "default"|"egrepify"
---@field previewer? fun(): table
---@field query_filter fun(query: string): string
local config = {}

---@return obsidian-kensaku.config.SetupOpts
config.default = function()
  return {}
end

---@type fun(opts: any): obsidian-kensaku.config
config.normalize = (function()
  local default = config.default()

  return function(opts)
    local options = vim.tbl_extend("force", default, opts or {})

    config.dict_path = options.dict_path

    if type(options.query_filter) == "function" then
      config.query_filter = options.query_filter
    else
      config.query_filter = filters.default
    end

    config.picker = options.picker
    config.previewer = options.previewer

    return config
  end
end)()

return config

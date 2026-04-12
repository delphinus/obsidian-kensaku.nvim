local Path = require "plenary.path"

local filters = require "obsidian-kensaku.filters"

---@class obsidian-kensaku.config.SetupOpts
---@field dict_path? string Path to migemo-compact-dict file. Auto-detected if not specified.
---@field picker? "default"|"egrepify" default: "default"
---@field previewer? fun(): table function that returns a telescope previewer
---@field query_filter? fun(query: string): string Custom filter function for grep (PCRE regex). Overrides built-in migemo.

---@class obsidian-kensaku.config
---@field dict_path string
---@field picker "default"|"egrepify"
---@field previewer? fun(): table
---@field query_filter fun(query: string): string
local config = {}

---@return obsidian-kensaku.config.SetupOpts
config.default = function()
  return {}
end

local DICT_URL = "https://github.com/oguna/migemo-compact-dict-latest/releases"

---@param dict_path? string
---@return string
local function search_compact_dict(dict_path)
  if dict_path then
    local p = Path:new(dict_path)
    if p:exists() then
      return p:absolute()
    end
    error("compact dict not found: " .. dict_path)
  end
  local candidates = {
    vim.fn.expand "~/.cache/kensaku.vim/migemo-compact-dict",
    vim.fn.stdpath "data" .. "/migemo-compact-dict",
  }
  for _, path in ipairs(candidates) do
    if Path:new(path):exists() then
      return path
    end
  end
  error("Could not find migemo-compact-dict. Download from " .. DICT_URL .. " or set dict_path in setup().")
end

---@type fun(opts: any): obsidian-kensaku.config
config.normalize = (function()
  local default = config.default()

  return function(opts)
    local options = vim.tbl_extend("force", default, opts or {})

    config.dict_path = search_compact_dict(options.dict_path)

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

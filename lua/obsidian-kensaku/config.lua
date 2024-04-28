local Path = require "plenary.path"

local filters = require "obsidian-kensaku.filters"

---@class obsidian-kensaku.config.SetupOpts
---@field cmigemo_executable? string default: "cmigemo"
---@field migemo_dict_path? string default: see README
---@field picker? "default"|"egrepify" default: "default"
---@field query_filter? "kensaku"|"cmigemo"|fun(query: string): string default: "kensaku"

---@class obsidian-kensaku.config
---@field cmigemo_executable string
---@field migemo_dict_path string
---@field picker "default"|"egrepify"
---@field query_filter fun(query: string): string
local config = {}

---@return obsidian-kensaku.config.SetupOpts
config.default = function()
  return {
    query_filter = "kensaku",
    cmigemo_executable = "cmigemo",
  }
end

---@param migemo_dict_path? string
---@return string
local function search_migemo_dict(migemo_dict_path)
  if migemo_dict_path and Path:new(migemo_dict_path):exists() then
    return migemo_dict_path
  end
  local migemo_dict_dirs = {
    "/opt/homebrew/opt/cmigemo/share",
    "/usr/local/opt/cmigemo/share",
    "/usr/local/share/cmigemo",
    "/usr/local/share",
    "/usr/share/cmigemo",
    "/usr/share",
  }
  local migemo_dict_paths = { "migemo/utf-8/migemo-dict", "utf-8/migemo-dict", "migemo-dict" }
  for _, dir in ipairs(migemo_dict_dirs) do
    for _, path in ipairs(migemo_dict_paths) do
      local migemo_dict = Path:new(dir, path)
      if migemo_dict:exists() then
        return migemo_dict.filename
      end
    end
  end
  error "Could not find migemo dict"
end

---@type fun(opts: any): obsidian-kensaku.config
config.normalize = (function()
  local default = config.default()

  return function(opts)
    local options = vim.tbl_extend("force", default, opts or {})

    if type(options.query_filter) == "function" then
      config.query_filter = opts.query_filter
    elseif type(options.query_filter) == "string" then
      if not filters[options.query_filter] then
        error("Invalid opts.query_filter: " .. options.query_filter)
      end
      config.query_filter = filters[options.query_filter]

      if options.query_filter == "cmigemo" then
        config.migemo_dict_path = search_migemo_dict(options.migemo_dict_path)
        config.cmigemo_executable = options.cmigemo_executable
      end
    else
      error "Invalid opts.query_filter"
    end

    config.picker = options.picker

    return config
  end
end)()

return config

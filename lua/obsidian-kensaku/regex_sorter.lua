local sorters = require "telescope.sorters"

---@type table<string, vim.regex>
local cache = {}

return sorters.Sorter:new {
  ---@param prompt string
  ---@param line string
  ---@param entry table
  ---@return number
  scoring_function = function(_, prompt, line, entry)
    if #prompt == 0 then
      return 1
    end
    if not cache[prompt] then
      cache[prompt] = vim.regex(prompt)
    end
    return not not cache[prompt]:match_str(line) and 1 or -1
  end,

  ---@param prompt string
  ---@param display string
  highlighter = function(_, prompt, display)
    if #prompt == 0 then
      return {}
    end

    local start, finish = vim.regex(prompt):match_str(display)
    return start and finish and { { start = start, finish = finish } } or {}
  end,
}

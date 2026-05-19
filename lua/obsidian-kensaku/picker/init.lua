local Picker = require "obsidian.picker"
local PickerName = require("obsidian.config").Picker
local log = require "obsidian.log"
local api = require "obsidian.api"

local config = require "obsidian-kensaku.config"

local M = {}

---@return string|nil
local function active_picker_name()
  if Obsidian and Obsidian.opts and Obsidian.opts.picker and Obsidian.opts.picker.name then
    return Obsidian.opts.picker.name
  end
  -- Match obsidian.nvim's auto-detection order in Obsidian.picker.get().
  for _, info in ipairs {
    { PickerName.telescope, "telescope.builtin" },
    { PickerName.fzf_lua, "fzf-lua" },
    { PickerName.snacks, "snacks.picker" },
    { PickerName.mini, "mini.pick" },
  } do
    if pcall(require, info[2]) then
      return info[1]
    end
  end
  return nil
end

---Run rg with a regex pattern under the vault and return parsed picker entries.
---Synchronous; intended for one-shot grep where the query is already known.
---@param regex string
---@param dir string|obsidian.Path
---@return obsidian.PickerEntry[]
local function rg_to_entries(regex, dir)
  local cmd = {
    "rg",
    "--vimgrep",
    "--no-heading",
    "--smart-case",
    "--color=never",
    "--type=md",
    "--",
    regex,
    tostring(dir),
  }
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 and result.code ~= 1 then
    log.err("obsidian-kensaku: rg exited with code %d: %s", result.code, result.stderr or "")
    return {}
  end

  local entries = {}
  for line in (result.stdout or ""):gmatch "[^\n]+" do
    local fname, lnum, col, text = line:match "^(.-):(%d+):(%d+):(.*)$"
    if fname then
      entries[#entries + 1] = {
        filename = fname,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
        value = text,
      }
    end
  end
  return entries
end

---@param opts? table
M.find_notes = function(opts)
  local name = active_picker_name()
  if name == PickerName.telescope then
    require("obsidian-kensaku.picker._telescope").find_notes(opts)
    return
  end
  log.err(
    "obsidian-kensaku: filename search with migemo is currently telescope.nvim only "
      .. "(active picker: %s). Support for fzf-lua / snacks.picker is planned.",
    name or "default"
  )
end

---@param opts? { query?: string, dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(entry: table) }
M.grep_notes = function(opts)
  opts = opts or {}
  local name = active_picker_name()

  if name == PickerName.telescope then
    require("obsidian-kensaku.picker._telescope").grep_notes(opts)
    return
  end

  if not (opts.query and #opts.query > 0) then
    log.err(
      "obsidian-kensaku: live grep with migemo is currently telescope.nvim only "
        .. "(active picker: %s). Pass an initial query (`:Obsidian kensaku <query>`) "
        .. "to use the one-shot mode supported by all pickers.",
      name or "default"
    )
    return
  end

  local dir = opts.dir or Obsidian.dir
  local regex = config.query_filter(opts.query)
  local entries = rg_to_entries(regex, dir)
  if #entries == 0 then
    log.info("obsidian-kensaku: no matches for `%s`.", opts.query)
    return
  end

  Picker.pick(entries, {
    prompt_title = opts.prompt_title or ("Grep notes (migemo): " .. opts.query),
    callback = opts.callback or function(entry)
      if entry then
        api.open_note(entry)
      end
    end,
  })
end

return M

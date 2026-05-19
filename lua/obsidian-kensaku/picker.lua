local telescope = require "telescope"
local telescope_builtin = require "telescope.builtin"
local telescope_actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"

local Path = require "obsidian.path"
local Picker = require "obsidian.picker"
local log = require "obsidian.log"
local search = require "obsidian.search"

local config = require "obsidian-kensaku.config"

local M = {}

---@param prompt_bufnr integer
---@param keep_open boolean|?
---@return table|?
local function get_entry(prompt_bufnr, keep_open)
  local entry = actions_state.get_selected_entry()
  if entry and not keep_open then
    telescope_actions.close(prompt_bufnr)
  end
  return entry
end

---@param prompt_bufnr integer
---@param keep_open boolean|?
---@param initial_query string|?
---@return string|?
local function get_query(prompt_bufnr, keep_open, initial_query)
  local query = actions_state.get_current_line()
  if not query or string.len(query) == 0 then
    query = initial_query
  end
  if query and string.len(query) > 0 then
    if not keep_open then
      telescope_actions.close(prompt_bufnr)
    end
    return query
  end
end

---@param prompt_bufnr integer
---@param keep_open boolean|?
---@param allow_multiple boolean|?
---@return table[]|?
local function get_selected(prompt_bufnr, keep_open, allow_multiple)
  local picker = actions_state.get_current_picker(prompt_bufnr)
  local entries = picker:get_multi_selection()
  if entries and #entries > 0 then
    if #entries > 1 and not allow_multiple then
      log.err "This mapping does not allow multiple entries"
      return
    end

    if not keep_open then
      telescope_actions.close(prompt_bufnr)
    end

    return entries
  else
    local entry = get_entry(prompt_bufnr, keep_open)

    if entry then
      return { entry }
    end
  end
end

---@param map fun(modes: string[], key: string, callback: fun(prompt_bufnr: integer))
---@param opts { entry_key: string|?, callback: fun(path: string)|?, allow_multiple: boolean|?, query_mappings: obsidian.PickerMappingTable|?, selection_mappings: obsidian.PickerMappingTable|?, initial_query: string|? }
local function attach_picker_mappings(map, opts)
  local function entry_to_value(entry)
    if opts.entry_key then
      return entry[opts.entry_key]
    else
      return entry
    end
  end

  if opts.query_mappings then
    for key, mapping in pairs(opts.query_mappings) do
      map({ "i", "n" }, key, function(prompt_bufnr)
        local query = get_query(prompt_bufnr, false, opts.initial_query)
        if query then
          mapping.callback(query)
        end
      end)
    end
  end

  if opts.selection_mappings then
    for key, mapping in pairs(opts.selection_mappings) do
      map({ "i", "n" }, key, function(prompt_bufnr)
        local entries = get_selected(prompt_bufnr, mapping.keep_open, mapping.allow_multiple)
        if entries then
          local values = vim.tbl_map(entry_to_value, entries)
          mapping.callback(unpack(values))
        elseif mapping.fallback_to_query then
          local query = get_query(prompt_bufnr, mapping.keep_open)
          if query then
            mapping.callback(query)
          end
        end
      end)
    end
  end

  if opts.callback then
    map({ "i", "n" }, "<CR>", function(prompt_bufnr)
      local entries = get_selected(prompt_bufnr, false, opts.allow_multiple)
      if entries then
        local values = vim.tbl_map(entry_to_value, entries)
        opts.callback(unpack(values))
      end
    end)
  end
end

---@param opts? { dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(path: string), query_mappings?: obsidian.PickerMappingTable, selection_mappings?: obsidian.PickerMappingTable, no_default_mappings?: boolean }
M.find_notes = function(opts)
  opts = opts or {}

  local query_mappings, selection_mappings
  if not opts.no_default_mappings then
    query_mappings = opts.query_mappings or Picker._note_query_mappings()
    selection_mappings = opts.selection_mappings or Picker._note_selection_mappings()
  else
    query_mappings = opts.query_mappings
    selection_mappings = opts.selection_mappings
  end

  telescope_builtin.find_files {
    prompt_title = opts.prompt_title or "Notes",
    cwd = opts.dir and tostring(opts.dir) or tostring(Obsidian.dir),
    previewer = config.previewer and config.previewer() or nil,
    find_command = search.build_find_cmd(nil, nil, { include_non_markdown = false }),
    sorter = require "obsidian-kensaku.regex_sorter",
    on_input_filter_cb = function(prompt)
      local migemo = require "luamigemo"
      local m = migemo.get(config.dict_path)
      local result = m:query(prompt, migemo.RXOP_VIM)
      return { prompt = migemo.VIM_PREFIX .. result }
    end,
    attach_mappings = function(_, map)
      attach_picker_mappings(map, {
        entry_key = "path",
        callback = opts.callback,
        query_mappings = query_mappings,
        selection_mappings = selection_mappings,
      })
      return true
    end,
  }
end

---@param opts? { dir?: string|obsidian.Path, query?: string, prompt_title?: string, callback?: fun(entry: table), query_mappings?: obsidian.PickerMappingTable, selection_mappings?: obsidian.PickerMappingTable, no_default_mappings?: boolean }
M.grep_notes = function(opts)
  opts = opts or {}

  local cwd = opts.dir and Path.new(opts.dir) or Obsidian.dir

  local query_mappings, selection_mappings
  if not opts.no_default_mappings then
    query_mappings = opts.query_mappings or Picker._note_query_mappings()
    selection_mappings = opts.selection_mappings or Picker._note_selection_mappings()
  else
    query_mappings = opts.query_mappings
    selection_mappings = opts.selection_mappings
  end

  local attach_mappings = function(_, map)
    attach_picker_mappings(map, {
      entry_key = "path",
      callback = opts.callback,
      query_mappings = query_mappings,
      selection_mappings = selection_mappings,
      initial_query = opts.query,
    })
    return true
  end

  local egrepify
  if config.picker == "egrepify" then
    local ext = telescope.extensions.egrepify
    if not ext then
      error "telescope-egrepify is not installed"
    end
    egrepify = ext.egrepify
  end

  local previewer = config.previewer and config.previewer() or nil
  local prompt_title = opts.prompt_title or "Grep notes"

  if opts.query and string.len(opts.query) > 0 then
    telescope_builtin.grep_string {
      prompt_title = prompt_title,
      cwd = tostring(cwd),
      previewer = previewer,
      vimgrep_arguments = search.build_grep_cmd { fixed_strings = false },
      search = config.query_filter(opts.query),
      attach_mappings = attach_mappings,
    }
  else
    local picker = egrepify or telescope_builtin.live_grep
    picker {
      prompt_title = prompt_title,
      cwd = tostring(cwd),
      previewer = previewer,
      vimgrep_arguments = search.build_grep_cmd { fixed_strings = false },
      attach_mappings = attach_mappings,
      ---@param prompt string
      ---@return { prompt: string }
      on_input_filter_cb = function(prompt)
        return { prompt = config.query_filter(prompt) }
      end,
    }
  end
end

return M

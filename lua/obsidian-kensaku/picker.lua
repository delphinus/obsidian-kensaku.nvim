local telescope = require "telescope"
local telescope_builtin = require "telescope.builtin"
local telescope_actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"

local Path = require "obsidian.path"
local abc = require "obsidian.abc"
local TelescopePicker = require "obsidian.pickers._telescope"
local log = require "obsidian.log"

local config = require "obsidian-kensaku.config"

---@class obsidian.pickers.KensakuPicker : obsidian.pickers.TelescopePicker
local KensakuPicker = abc.new_class({
  ---@diagnostic disable-next-line: unused-local
  __tostring = function(self)
    return "KensakuPicker()"
  end,
}, TelescopePicker)

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
  else
    return nil
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

---@param opts { entry_key: string|?, callback: fun(path: string)|?, allow_multiple: boolean|?, query_mappings: obsidian.PickerMappingTable|?, selection_mappings: obsidian.PickerMappingTable|?, initial_query: string|? }
local function attach_picker_mappings(map, opts)
  -- Docs for telescope actions:
  -- https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/actions/init.lua

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

---@param opts obsidian.PickerGrepOpts|? Options.
KensakuPicker.grep = function(self, opts)
  opts = opts or {}

  local cwd = opts.dir and Path:new(opts.dir) or self.client.dir

  local prompt_title = self:_build_prompt {
    prompt_title = opts.prompt_title,
    query_mappings = opts.query_mappings,
    selection_mappings = opts.selection_mappings,
  }

  local attach_mappings = function(_, map)
    attach_picker_mappings(map, {
      entry_key = "path",
      callback = opts.callback,
      query_mappings = opts.query_mappings,
      selection_mappings = opts.selection_mappings,
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

  if opts.query and string.len(opts.query) > 0 then
    telescope_builtin.grep_string {
      prompt_title = prompt_title,
      cwd = tostring(cwd),
      vimgrep_arguments = self:_build_grep_cmd(),
      search = config.query_filter(opts.query),
      attach_mappings = attach_mappings,
    }
  else
    local picker = egrepify or telescope_builtin.live_grep
    picker {
      prompt_title = prompt_title,
      cwd = tostring(cwd),
      vimgrep_arguments = self:_build_grep_cmd(),
      attach_mappings = attach_mappings,
      ---@param prompt string
      ---@return { prompt: string }
      on_input_filter_cb = function(prompt)
        return { prompt = config.query_filter(prompt) }
      end,
    }
  end
end

KensakuPicker._build_grep_cmd = function(self)
  local search = require "obsidian.search"
  local search_opts = search.SearchOpts.from_tbl {
    sort_by = self.client.opts.sort_by,
    sort_reversed = self.client.opts.sort_reversed,
    smart_case = true,
  }
  return search.build_grep_cmd(search_opts)
end

return KensakuPicker

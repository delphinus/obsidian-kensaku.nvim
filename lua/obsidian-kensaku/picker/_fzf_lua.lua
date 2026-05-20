local Path = require "obsidian.path"

local config = require "obsidian-kensaku.config"

local M = {}

---Build a PCRE regex string for the user's romaji input via migemo, with
---FLAG_NFD so that NFD-decomposed filenames on macOS APFS / iCloud Drive
---also match. Returns nil for an empty query.
---@param query string
---@return string|nil
local function build_filename_pcre(query)
  if not query or query == "" then
    return nil
  end
  local migemo = require "luamigemo"
  local m = migemo.get(config.dict_path)
  local flags = migemo.FLAG_NFD or 0
  return m:query(query, migemo.RXOP_PCRE, flags)
end

---Wrap a shell command so that a non-zero exit status (e.g. rg returning 1
---on no matches) does not surface a "command failed" UI in fzf-lua.
---@param cmd string
---@return string
local function silence_no_match(cmd)
  return cmd .. " || true"
end

---@param opts? { dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(path: string) }
M.find_notes = function(opts)
  opts = opts or {}
  local cwd = opts.dir and tostring(opts.dir) or tostring(Obsidian.dir)
  local fzf = require "fzf-lua"

  -- fzf_live calls `contents(query, opts)` on each keystroke; we return
  -- a shell command that pipes `rg --files` through a second `rg` doing
  -- the migemo PCRE match. Two `rg`s per keystroke (~50ms total) — well
  -- within fzf-lua's input cadence. We do this in a subprocess because
  -- `vim.regex` against a multi-KB migemo alternation takes 1-5 seconds
  -- per query (see PR #8).
  fzf.fzf_live(function(query, _o)
    local q = query and query[1] or ""
    local regex = build_filename_pcre(q)
    if not regex then
      return ""
    end
    return silence_no_match(
      string.format("rg --files --type md %s | rg --regexp %s", vim.fn.shellescape(cwd), vim.fn.shellescape(regex))
    )
  end, {
    prompt = (opts.prompt_title or "Notes (migemo)") .. "> ",
    cwd = cwd,
    -- Keep raw paths in entries so we don't have to strip device icons
    -- when parsing the selection.
    file_icons = false,
    git_icons = false,
    actions = {
      ["default"] = function(selected, _o)
        local path = selected and selected[1]
        if not path or path == "" then
          return
        end
        if opts.callback then
          opts.callback(path)
        else
          vim.cmd.edit(vim.fn.fnameescape(path))
        end
      end,
    },
  })
end

---@param opts? { dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(entry: table) }
M.grep_notes = function(opts)
  opts = opts or {}
  local cwd = opts.dir and Path.new(opts.dir) or Obsidian.dir
  local cwd_str = tostring(cwd)
  local fzf = require "fzf-lua"

  fzf.fzf_live(function(query, _o)
    local q = query and query[1] or ""
    if q == "" then
      return ""
    end
    -- Use the project's query_filter so users can override the romaji
    -- conversion. Default is migemo PCRE without VIM_PREFIX.
    local regex = config.query_filter(q)
    return silence_no_match(
      string.format(
        "rg --vimgrep --no-heading --smart-case --color=never --type=md -- %s %s",
        vim.fn.shellescape(regex),
        vim.fn.shellescape(cwd_str)
      )
    )
  end, {
    prompt = (opts.prompt_title or "Grep notes (migemo)") .. "> ",
    cwd = cwd_str,
    file_icons = false,
    git_icons = false,
    actions = {
      ["default"] = function(selected, _o)
        local line = selected and selected[1]
        if not line or line == "" then
          return
        end
        local fname, lnum, col, text = line:match "^(.-):(%d+):(%d+):(.*)$"
        if not fname then
          return
        end
        local item = {
          cwd = cwd_str,
          file = fname,
          pos = { tonumber(lnum), tonumber(col) - 1 },
          text = text,
        }
        if opts.callback then
          opts.callback(item)
        else
          vim.cmd.edit(vim.fn.fnameescape(item.file))
          if item.pos and item.pos[1] then
            vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] or 0 })
          end
        end
      end,
    },
  })
end

return M

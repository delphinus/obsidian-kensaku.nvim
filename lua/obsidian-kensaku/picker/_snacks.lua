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

---@param opts? { dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(path: string) }
M.find_notes = function(opts)
  opts = opts or {}
  local cwd = opts.dir and tostring(opts.dir) or tostring(Obsidian.dir)

  Snacks.picker.pick {
    title = opts.prompt_title or "Notes (migemo)",
    cwd = cwd,
    live = true,
    format = "file",
    -- Filter `rg --files` through a second `rg` that matches the migemo
    -- PCRE regex against each path. We do this in a subprocess instead of
    -- in-process `vim.regex` for two reasons:
    --
    --   1. Safety. Calling `vim.regex:match_str()` from snacks's
    --      check-handle coroutine re-enters `loop_poll_events` from
    --      inside its own iteration and aborts the process. The outer
    --      `picker:find()` runs in `vim.schedule` so the *outer* finder
    --      could call `vim.regex` safely, but the inner async cb cannot.
    --   2. Speed. Migemo expands short queries (e.g. "k") into ~10 KB
    --      alternations with thousands of kanji. vim.regex's NFA/old
    --      engines scan the full string on a miss, taking 1-5 s on a few
    --      thousand files. rg's Aho-Corasick + DFA stays under 100 ms.
    finder = function(_finder_opts, ctx)
      local regex = build_filename_pcre(ctx.filter.search)
      if not regex then
        return function() end
      end
      return require("snacks.picker.source.proc").proc(
        ctx:opts {
          notify = false,
          cmd = "sh",
          args = {
            "-c",
            string.format(
              "rg --files --type md %s | rg --regexp %s",
              vim.fn.shellescape(cwd),
              vim.fn.shellescape(regex)
            ),
          },
          transform = function(item)
            item.cwd = cwd
            item.file = item.text
            return item
          end,
        },
        ctx
      )
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local path = item.file or item.text
      if opts.callback then
        opts.callback(path)
      else
        vim.cmd.edit(vim.fn.fnameescape(path))
      end
    end,
  }
end

---Build rg vimgrep args for the given migemo PCRE regex.
---@param regex string PCRE pattern
---@param cwd string
---@return string[]
local function build_grep_args(regex, cwd)
  return {
    "--vimgrep",
    "--no-heading",
    "--smart-case",
    "--color=never",
    "--type=md",
    "--",
    regex,
    cwd,
  }
end

---@param opts? { dir?: string|obsidian.Path, prompt_title?: string, callback?: fun(entry: table) }
M.grep_notes = function(opts)
  opts = opts or {}
  local cwd = opts.dir and Path.new(opts.dir) or Obsidian.dir
  local cwd_str = tostring(cwd)

  Snacks.picker.pick {
    title = opts.prompt_title or "Grep notes (migemo)",
    cwd = cwd_str,
    live = true,
    format = "file",
    finder = function(_finder_opts, ctx)
      local query = ctx.filter.search
      if not query or query == "" then
        return function() end
      end
      -- Use the project's query_filter so users can override the romaji
      -- conversion. Default is migemo PCRE without VIM_PREFIX.
      local regex = config.query_filter(query)
      return require("snacks.picker.source.proc").proc(
        ctx:opts {
          notify = false,
          cmd = "rg",
          args = build_grep_args(regex, cwd_str),
          transform = function(item)
            local fname, lnum, col, text = item.text:match "^(.-):(%d+):(%d+):(.*)$"
            if not fname then
              return false
            end
            item.cwd = cwd_str
            item.file = fname
            item.pos = { tonumber(lnum), tonumber(col) - 1 }
            item.text = text
            return item
          end,
        },
        ctx
      )
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if opts.callback then
        opts.callback(item)
      else
        vim.cmd.edit(vim.fn.fnameescape(item.file))
        if item.pos and item.pos[1] then
          vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] or 0 })
        end
      end
    end,
  }
end

return M

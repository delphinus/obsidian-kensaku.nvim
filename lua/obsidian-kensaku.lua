local done

return {
  ---@param opts obsidian-kensaku.config.SetupOpts
  setup = function(opts)
    ---@param client obsidian.Client
    return function(client)
      if not done then
        require("obsidian-kensaku.config").normalize(opts)
        done = true
      end
      vim.api.nvim_create_user_command("ObsidianKensaku", function(data)
        local picker = require("obsidian-kensaku.picker").new(client)
        picker:grep_notes { query = data.args }
      end, { nargs = "?", desc = "Search vault with kensaku.vim" })
    end
  end,
}

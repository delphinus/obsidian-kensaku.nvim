---@class obsidian-kensaku
---@field setup_called boolean
---@field setup fun(opts?: obsidian-kensaku.config.SetupOpts)
---@overload fun(client: obsidian.Client)

return setmetatable({ setup_called = false }, {
  ---@param client obsidian.Client
  __call = function(self, client)
    if not self.setup_called then
      self.setup()
    end
    vim.api.nvim_create_user_command("ObsidianKensaku", function(data)
      local picker = require("obsidian-kensaku.picker").new(client)
      picker:grep_notes { query = data.args }
    end, { nargs = "?", desc = "Search vault with kensaku.vim" })
  end,
  ---@param key string
  __index = function(self, key)
    if key == "setup" then
      ---@param opts obsidian-kensaku.config.SetupOpts
      return function(opts)
        require("obsidian-kensaku.config").normalize(opts)
        self.setup_called = true
      end
    end
    error("Invalid key: " .. key)
  end,
}) --[[@as obsidian-kensaku]]

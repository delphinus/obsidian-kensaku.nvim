---@class obsidian-kensaku
---@field setup_called boolean
---@field setup fun(opts?: obsidian-kensaku.config.SetupOpts)

local function register_commands()
  local ok, obsidian_commands = pcall(require, "obsidian.commands")
  if ok then
    obsidian_commands.register("kensaku", {
      nargs = "?",
      func = function(data)
        require("obsidian-kensaku.picker").grep_notes { query = data.args }
      end,
    })
    obsidian_commands.register("quick_kensaku", {
      nargs = 0,
      func = function()
        require("obsidian-kensaku.picker").find_notes()
      end,
    })
  end

  vim.api.nvim_create_user_command("ObsidianKensaku", function(data)
    require("obsidian-kensaku.picker").grep_notes { query = data.args }
  end, { nargs = "?", desc = "Search vault with migemo (legacy; use :Obsidian kensaku)" })
  vim.api.nvim_create_user_command("ObsidianQuickKensaku", function()
    require("obsidian-kensaku.picker").find_notes()
  end, { nargs = 0, desc = "Search vault filenames with migemo (legacy; use :Obsidian quick_kensaku)" })
end

return setmetatable({ setup_called = false }, {
  ---@param key string
  __index = function(self, key)
    if key == "setup" then
      ---@param opts? obsidian-kensaku.config.SetupOpts
      return function(opts)
        require("obsidian-kensaku.config").normalize(opts)
        if not self.setup_called then
          register_commands()
          self.setup_called = true
        end
      end
    end
    error("Invalid key: " .. key)
  end,
}) --[[@as obsidian-kensaku]]

# obsidian-kensaku.nvim

[!demo.png]

Search the vault with roma-ji powered by [epwalsh/obsidian.nvim][].

[epwalsh/obsidian.nvim]: https://github.com/epwalsh/obsidian.nvim

## What's this?

This plugin adds a command `:ObsidianKensaku`. This command looks like
`:ObsidianSearch` but you can use roma-ji to search the vault.

## Requirements

* [epwalsh/obsidian.nvim][]
* [nvim-telescope/telescope.nvim][]
  - obsidian.nvim supports telescope, [ibhagwan/fzf-lua][] and
    [echasnovski/mini.pick][], but obsidian-kensaku.nvim supports telescope.nvim
    only.
* Converter for roma-ji. You needs one of below.
  - [lambdalisue/kensaku.vim][]
  - `cmigemo` executable.
  - or another one you prefer.

[nvim-telescope/telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ibhagwan/fzf-lua]: https://github.com/ibhagwan/fzf-lua
[echasnovski/mini.pick]: https://github.com/echasnovski/mini.pick
[lambdalisue/kensaku.vim]: https://github.com/lambdalisue/kensaku.vim

## Install

### Set up converter for roma-ji

You can choose one.

#### kensaku.vim

See [lambdalisue/kensaku.vim][] for the detail.

```lua
-- example for lazy.nvim
{
  "lambdalisue/kensaku.vim",
  dependencies = { "vim-denops/denops.vim" },
}
```

#### `cmigemo` executable

You can install by OS specific command.

```bash
# macOS
brew install cmigemo

# some Linux's
apt-get install cmigemo
```

For Windows or other Linux's, see [C/Migemo — KaoriYa][].

[C/Migemo — KaoriYa]: https://www.kaoriya.net/software/cmigemo/

[vim-denops/denops.vim]: https://github.com/vim-denops/denops.vim

### Add this plugin with your favorite plugin manager

If you use kensaku.vim (the default way), you can set simply like this below.

```lua
-- example for lazy.nvim
{
  "epwalsh/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "delphinus/obsidian-kensaku.nvim",
  },
  opts = {
    callbacks = {
      post_setup = function(client)
        require("obsidian-kensaku")(client),
      end,
    },
  },
}
```

> [!IMPORTANT]
> Remember to call this plugin in `opts.callbacks.post_setup`.

If you want to customize the way, call `setup` or write them in `opts` (for
[lazy.nvim](https://github.com/folke/lazy.nvim)).

```lua
-- example for lazy.nvim
{
  "epwalsh/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "delphinus/obsidian-kensaku.nvim",
      opts = {
        query_filter = "cmigemo",
        cmigemo_executable = "/path/to/cmigemo",
        migemo_dict_path = "/path/to/migemo-dict",
      },
      --- for other plugin managers
      -- config = function()
      --   require("obsidian-kensaku").setup {
      --     query_filter = "cmigemo",
      --     cmigemo_executable = "/path/to/cmigemo",
      --     migemo_dict_path = "/path/to/migemo-dict",
      --   }
      -- end,
    },
  },
  opts = {
    callbacks = {
      post_setup = function(client)
        require("obsidian-kensaku")(client),
      end,
    },
  },
}
```

## Options

### `query_filter`

* default: `"kensaku"`
* type: `"kensaku"|"cmigemo"|fun(query: string): string`

You can choose the way to convert roma-ji into regex. It has pre-defined
filters for [lambdalisue/kensaku.vim] and `cmigemo`, but you can defined your
own way to do this.

```lua
{
  query_filter = function(query)
    return some_way_to_create_regex(query)
  end,
}
```

### `cmigemo_executable`

* default: `"cmigemo"`
* type: `string`

Path for `cmigemo` executable. This will be used only if `query_filter` is
`"cmigemo"`.

### `migemo_dict_path`

* default: Search automatically. See [lua/obsidian-kensaku/config.lua][].
* type: `string`

[lua/obsidian-kensaku/config.lua]: lua/obsidian-kensaku/config.lua

Path for `migemo-dict`. This will be used only if `query_filter` is `"cmigemo"`.

## LICENSE

MIT license.

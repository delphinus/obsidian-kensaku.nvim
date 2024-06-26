# obsidian-kensaku.nvim

<img alt="demo-egrepify" width="640" src="demo-egrepify.png">

Search the vault with Romaji powered by [epwalsh/obsidian.nvim][].

ローマ字を使って [epwalsh/obsidian.nvim][] の文書を検索します。

[epwalsh/obsidian.nvim]: https://github.com/epwalsh/obsidian.nvim

## What's this?

This plugin adds a command `:ObsidianKensaku`. This command looks like
`:ObsidianSearch` but you can use Romaji to search the vault.

## Requirements

* [epwalsh/obsidian.nvim][]
* [nvim-telescope/telescope.nvim][]
  - obsidian.nvim supports telescope, [ibhagwan/fzf-lua][] and
    [echasnovski/mini.pick][], but obsidian-kensaku.nvim supports telescope.nvim
    only.
* Converter for Romaji. You needs one of below.
  - [lambdalisue/kensaku.vim][]
  - `cmigemo` executable.
  - or another one you prefer.
* [fdschmidt93/telescope-egrepify.nvim][] _(optional)_
  - telescope has a bug (https://github.com/nvim-telescope/telescope.nvim/issues/2272)
    that it cannot highlight properly with string matched by regex. I recommend
    you to use telescope-egrepify for this.

[nvim-telescope/telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ibhagwan/fzf-lua]: https://github.com/ibhagwan/fzf-lua
[echasnovski/mini.pick]: https://github.com/echasnovski/mini.pick
[lambdalisue/kensaku.vim]: https://github.com/lambdalisue/kensaku.vim
[fdschmidt93/telescope-egrepify.nvim]: https://github.com/fdschmidt93/telescope-egrepify.nvim

## Install

### Set up converter for Romaji

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
        require "obsidian-kensaku"(client),
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
        require "obsidian-kensaku"(client),
      end,
    },
  },
}
```

## Command

### `:ObsidianKensaku`

Open the picker like `:ObsidianSearch`. You can search with Romaji and do the
same things as in `:ObsidianSearch`.

## Options

### `query_filter`

* default: `"kensaku"`
* type: `"kensaku"|"cmigemo"|fun(query: string): string`

You can choose the way to convert Romaji into regex. It has pre-defined
filters for [lambdalisue/kensaku.vim] and `cmigemo`, but you can define your
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

### `picker`

* default: `"default"`
* type: `"default"|"egrepify"`

Use [fdschmidt93/telescope-egrepify.nvim][] instead of telescope's builtin.

## LICENSE

MIT license.

# obsidian-kensaku.nvim

<img alt="demo-egrepify" width="640" src="demo-egrepify.png">

Search the vault with Romaji powered by [epwalsh/obsidian.nvim][].

ローマ字を使って [epwalsh/obsidian.nvim][] の文書を検索します。

[epwalsh/obsidian.nvim]: https://github.com/epwalsh/obsidian.nvim

## What's this?

This plugin adds a command `:ObsidianKensaku`. This command looks like
`:ObsidianSearch` but you can use Romaji to search the vault.

Romaji input is converted to regex using [delphinus/luamigemo][] (a pure Lua
migemo engine). No external binaries or separate processes are required.

[delphinus/luamigemo]: https://github.com/delphinus/luamigemo

## Requirements

* [epwalsh/obsidian.nvim][]
* [delphinus/luamigemo][]
* [nvim-telescope/telescope.nvim][]
  - obsidian.nvim supports telescope, [ibhagwan/fzf-lua][] and
    [echasnovski/mini.pick][], but obsidian-kensaku.nvim supports telescope.nvim
    only.
* A migemo compact dictionary file (auto-detected or manually specified; see
  [Dictionary](#dictionary) below)
* [fdschmidt93/telescope-egrepify.nvim][] _(optional)_
  - telescope has a bug (https://github.com/nvim-telescope/telescope.nvim/issues/2272)
    that it cannot highlight properly with string matched by regex. I recommend
    you to use telescope-egrepify for this.

[nvim-telescope/telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ibhagwan/fzf-lua]: https://github.com/ibhagwan/fzf-lua
[echasnovski/mini.pick]: https://github.com/echasnovski/mini.pick
[fdschmidt93/telescope-egrepify.nvim]: https://github.com/fdschmidt93/telescope-egrepify.nvim

## Dictionary

This plugin uses a compact binary dictionary from
[oguna/migemo-compact-dict-latest][]. The dictionary is auto-detected from the
following locations:

1. `~/.cache/kensaku.vim/migemo-compact-dict` (cached by kensaku.vim)
2. `vim.fn.stdpath("data") .. "/migemo-compact-dict"`

If you have previously used [lambdalisue/kensaku.vim][], its cached dictionary
is reused automatically. Otherwise, download it manually:

```bash
# Download to Neovim's data directory
curl -fLo "$(nvim --headless -c 'echo stdpath("data")' -c 'qa!' 2>&1)/migemo-compact-dict" \
  https://github.com/oguna/migemo-compact-dict-latest/releases/download/v0.2/migemo-compact-dict
```

You can also specify a custom path via `dict_path` in setup.

[oguna/migemo-compact-dict-latest]: https://github.com/oguna/migemo-compact-dict-latest
[lambdalisue/kensaku.vim]: https://github.com/lambdalisue/kensaku.vim

## Install

### Pinning to a stable version

This plugin uses [SemVer](https://semver.org/). If you want to avoid breaking
changes, add `version = "*"` to your lazy.nvim spec. This tells lazy.nvim to
use the latest tagged release instead of the `main` branch:

```lua
{
  "delphinus/obsidian-kensaku.nvim",
  version = "*",
}
```

### Add this plugin with your favorite plugin manager

```lua
-- example for lazy.nvim
{
  "epwalsh/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "delphinus/obsidian-kensaku.nvim",
      version = "*",
      dependencies = { "delphinus/luamigemo" },
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

> [!IMPORTANT]
> Remember to call this plugin in `opts.callbacks.post_setup`.

If you want to customize the dictionary path or other options, call `setup` or
write them in `opts` (for [lazy.nvim](https://github.com/folke/lazy.nvim)).

```lua
-- example for lazy.nvim
{
  "epwalsh/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "delphinus/obsidian-kensaku.nvim",
      version = "*",
      dependencies = { "delphinus/luamigemo" },
      opts = {
        dict_path = "/path/to/migemo-compact-dict",
      },
      --- for other plugin managers
      -- config = function()
      --   require("obsidian-kensaku").setup {
      --     dict_path = "/path/to/migemo-compact-dict",
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

## Commands

### `:ObsidianKensaku`

Open the picker like `:ObsidianSearch`. You can search note **contents** with
Romaji and do the same things as in `:ObsidianSearch`.

### `:ObsidianQuickKensaku`

Open the picker like `:ObsidianQuickSwitch`. You can search notes by **file
name** with Romaji. This is the kensaku-powered equivalent of
`:ObsidianQuickSwitch`.

## Options

### `dict_path`

* default: (auto-detected)
* type: `string`

Path to the migemo-compact-dict file. If not specified, the plugin searches
common locations automatically (see [Dictionary](#dictionary) above).

### `query_filter`

* default: built-in Lua migemo
* type: `fun(query: string): string`

A custom function to convert Romaji input into a PCRE regex string for
grep-based search. Overrides the built-in migemo engine.

```lua
{
  query_filter = function(query)
    return some_way_to_create_regex(query)
  end,
}
```

### `picker`

* default: `"default"`
* type: `"default"|"egrepify"`

Use [fdschmidt93/telescope-egrepify.nvim][] instead of telescope's builtin.

### `previewer`

* default: `nil`
* type: `fun(): table`

A function that returns a custom telescope previewer. When set, it is used
for all picker commands. For example, [delphinus/md-render.nvim][] can render
Markdown in the preview window:

```lua
{
  previewer = function()
    return require("md-render.telescope").previewer()
  end,
}
```

[delphinus/md-render.nvim]: https://github.com/delphinus/md-render.nvim

## LICENSE

MIT license.

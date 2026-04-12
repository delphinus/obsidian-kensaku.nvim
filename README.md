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
* [delphinus/luamigemo][] (dictionary bundled — no extra download needed)
* [nvim-telescope/telescope.nvim][]
  - obsidian.nvim supports telescope, [ibhagwan/fzf-lua][] and
    [echasnovski/mini.pick][], but obsidian-kensaku.nvim supports telescope.nvim
    only.
* [fdschmidt93/telescope-egrepify.nvim][] _(optional)_
  - telescope has a bug (https://github.com/nvim-telescope/telescope.nvim/issues/2272)
    that it cannot highlight properly with string matched by regex. I recommend
    you to use telescope-egrepify for this.

[nvim-telescope/telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ibhagwan/fzf-lua]: https://github.com/ibhagwan/fzf-lua
[echasnovski/mini.pick]: https://github.com/echasnovski/mini.pick
[fdschmidt93/telescope-egrepify.nvim]: https://github.com/fdschmidt93/telescope-egrepify.nvim

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
      dependencies = { { "delphinus/luamigemo", version = "*" } },
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

If you want to customize options, call `setup` or write them in `opts` (for
[lazy.nvim](https://github.com/folke/lazy.nvim)).

```lua
-- example for lazy.nvim
{
  "epwalsh/obsidian.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "delphinus/obsidian-kensaku.nvim",
      version = "*",
      dependencies = { { "delphinus/luamigemo", version = "*" } },
      opts = {
        picker = "egrepify",
      },
      --- for other plugin managers
      -- config = function()
      --   require("obsidian-kensaku").setup {
      --     picker = "egrepify",
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

* default: `nil` (uses luamigemo's bundled dictionary)
* type: `string`

Path to a custom migemo-compact-dict file. If not specified, the bundled
dictionary included with [delphinus/luamigemo][] is used. You can use this
option to specify a larger dictionary such as the GPL-licensed one from
[oguna/migemo-compact-dict-latest][].

[oguna/migemo-compact-dict-latest]: https://github.com/oguna/migemo-compact-dict-latest

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

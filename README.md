# obsidian-kensaku.nvim

<img alt="demo-egrepify" width="640" src="demo-egrepify.png">

Search the vault with Romaji powered by [obsidian-nvim/obsidian.nvim][].

ローマ字を使って [obsidian-nvim/obsidian.nvim][] の文書を検索します。

[obsidian-nvim/obsidian.nvim]: https://github.com/obsidian-nvim/obsidian.nvim

> [!IMPORTANT]
> v3 onwards targets the [obsidian-nvim/obsidian.nvim][] fork only. If you are
> still on the archived [epwalsh/obsidian.nvim][], pin to the v2 line
> (`version = "^2.0"`).

[epwalsh/obsidian.nvim]: https://github.com/epwalsh/obsidian.nvim

## What's this?

This plugin adds a command `:ObsidianKensaku`. This command looks like
`:Obsidian search` but you can use Romaji to search the vault.

Romaji input is converted to regex using [delphinus/luamigemo][] (a pure Lua
migemo engine). No external binaries or separate processes are required.

[delphinus/luamigemo]: https://github.com/delphinus/luamigemo

## Requirements

* [obsidian-nvim/obsidian.nvim][]
* [delphinus/luamigemo][] (dictionary bundled — no extra download needed)
* [nvim-telescope/telescope.nvim][]
  - obsidian.nvim supports telescope, [ibhagwan/fzf-lua][],
    [echasnovski/mini.pick][], and [folke/snacks.nvim][], but
    obsidian-kensaku.nvim supports telescope.nvim only.
* [fdschmidt93/telescope-egrepify.nvim][] _(optional)_
  - telescope has a bug (https://github.com/nvim-telescope/telescope.nvim/issues/2272)
    that it cannot highlight properly with string matched by regex. I recommend
    you to use telescope-egrepify for this.

[nvim-telescope/telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ibhagwan/fzf-lua]: https://github.com/ibhagwan/fzf-lua
[echasnovski/mini.pick]: https://github.com/echasnovski/mini.pick
[folke/snacks.nvim]: https://github.com/folke/snacks.nvim
[fdschmidt93/telescope-egrepify.nvim]: https://github.com/fdschmidt93/telescope-egrepify.nvim

## Install

### Pinning to a stable version

This plugin uses [SemVer](https://semver.org/). The v3 line targets
[obsidian-nvim/obsidian.nvim][]; the v2 line targets the archived
[epwalsh/obsidian.nvim][]. Pin accordingly:

```lua
{
  "delphinus/obsidian-kensaku.nvim",
  version = "^3.0", -- for obsidian-nvim/obsidian.nvim
  -- version = "^2.0", -- for epwalsh/obsidian.nvim
}
```

### Add this plugin with your favorite plugin manager

```lua
-- example for lazy.nvim
{
  "delphinus/obsidian-kensaku.nvim",
  version = "^3.0",
  cmd = { "ObsidianKensaku", "ObsidianQuickKensaku" },
  dependencies = {
    "obsidian-nvim/obsidian.nvim",
    { "delphinus/luamigemo", version = "*" },
  },
  opts = {},
}
```

`opts = {}` makes lazy.nvim call `require("obsidian-kensaku").setup()` for you.
For other plugin managers, call `setup` manually:

```lua
require("obsidian-kensaku").setup {
  picker = "egrepify",
}
```

> [!NOTE]
> v2 required wiring the plugin from inside `opts.callbacks.post_setup` of
> obsidian.nvim. v3 drops that — `setup()` is self-contained, and obsidian.nvim
> only needs to have been initialized by the time you invoke a command. Listing
> `obsidian-nvim/obsidian.nvim` as a dependency (as above) handles that for you.

## Commands

### `:ObsidianKensaku`

Open the picker like `:Obsidian search`. You can search note **contents** with
Romaji and do the same things as in `:Obsidian search`.

### `:ObsidianQuickKensaku`

Open the picker like `:Obsidian quick_switch`. You can search notes by **file
name** with Romaji. This is the kensaku-powered equivalent of
`:Obsidian quick_switch`.

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

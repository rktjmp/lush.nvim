![Lush Header](../assets/images/header.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is a colorscheme creation aid for Neovim. It gives you real time
feedback as you edit, as well as color manipulation tools and some aids
building a structured colorscheme.

Lush colorschemes can easily be exported for use without Lush, either as
a lua table, vimscript commands or any other format. They can also be
imported into other Lua systems to access your color data.

See some colorschemes [**Made with Lush**](made_with_lush/README.md#made-with-lush).

- [Announcements](#Announcements)
- [Requirements](#requirements)
- [Installation](#installation)
- [Interactive Tutorial](#interactive-tutorial)
- [Guides](#guides)
- [See Also](#see-also)

Lush and modern Neovim
---

Lush was originally written for Neovim 0.4 (!!!). I had just swapped from Vim
to Neovim, wanted to learn Lua as well as make my own colorscheme. I read an
article by Leaf about [creating DSLs in
lua](https://leafo.net/guides/dsl-in-lua.html) and rolled all that into Lush.

At the time, there was no native support for writing colorschemes in Lua and
being able to export my Neovim colorscheme to use with AwesomeWM was a neat
trick. Neovim's APIs have matured and writing colorschemes in Lua is now quite
simple. You can approximate a custom implementation of Lush with some
metatables and glue.

**Lush will still be maintained** but the value proposition of Lush is
different to what it was at the time of release and creators may want to take
that under consideration.

Experimental Treesitter Interface
---

[See issue for new syntax](https://github.com/rktjmp/lush.nvim/issues/109).
Syntax is subject to change.

Announcements
------------

- 2022-05-12: Neovim 0.7 is now a requirement, the 1.0.1 tagged version
  is the last 0.5 compatible release.
- 2021-11-05: Deprecation warning, the compiler `exclude_keys` option has been
  deprecated in favour of the build system,
  - See [build guide](BUILD.md) for details.

Requirements
------------

- Neovim 0.7 or greater required to use Lush as a development tool
- `termguicolors` enabled for true color support

Installation
------------

Install via any package management system, for example, paq:

```vim
require paq { 'rktjmp/lush.nvim' }
```

Via Lazy:

```lua
return {
    "rktjmp/lush.nvim",
    -- if you wish to use your own colorscheme:
    -- { dir = '/absolute/path/to/colorscheme', lazy = true },
}
```

Interactive Tutorial
---------------------

![Lush Demo](../assets/images/demo.gif)

Run `:LushRunTutorial` for an Interactive guided tour of using Lush.

Guides
------

- [Create your new colorscheme with lush-template (and how to import a non-lush colorscheme)](CREATE.md)
- [Extend an Lush existing colorscheme, or how users can configure your
  colorscheme](EXTEND.md)
- [Export your colorscheme for use without Lush, or to any format with Shipwright](BUILD.md)
- [FAQ](FAQ.md)

See Also
--------

- [Vim Help](doc/lush.txt)
- [Change Log](CHANGELOG.md)
- [TODO](TODO.md)

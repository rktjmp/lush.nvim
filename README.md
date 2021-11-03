![Lush Header](../assets/images/header.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is aims to make colorscheme creation as painless as possible.

At its core, Lush presents your colorscheme as *structured data*, allowing
you to manipulate it in any way you want.

It comes with *as-you-edit feedback*, a selection of *color operation helpers*,
the ability for end users to *extend and configure colorschemes*, as well an
API to *export your colorscheme in any format*, including a configurable lua
colorscheme.

See some colorschemes [**Made with Lush**](made_with_lush/README.md#made-with-lush).

Annoucements
------------

- 2021-10-31: Breaking change, the compiler `exclude_keys` option has been
  removed in favour of the compiler plugin system,
  - You should now pass `{plugins:  {require("lush.compiler.plugin.vim_compatible")}}` instead.

Requirements
------------

- Neovim 0.5 or greater required to use Lush as a development tool
- `termguicolors` enabled for true color support

Installation
------------

Install via any package management system, for example, paq:

```vim
require paq { 'rktjmp/lush.nvim' }
```

Interactive Tutorials
---------------------

![Lush Demo](../assets/images/demo.gif)

There are two interactive tutorials provided,

- `:LushRunQuickstart` which will give you a few-minute overview of Lush's
  creation features. (Or open `lush_quick_start.lua` in the examples folder.)

- `:LushRunTutorial`, a more in-depth guide through various ways to apply Lush.
  (Or open `lush_tutorial.lua` in the examples folder).

Guides
------

- [Create your new colorscheme with lush-template](create_theme.md)
- [Extend an existing colorscheme, or how users can configure your
  colorscheme](extend_theme.md)
- [Export your theme to any format(s) with LushBuild](lush_build.md)
- [Questions and Queries](faq.md)

See Also
--------

- [Vim Help](doc/lush.txt)
- [Change Log](CHANGELOG.md)
- [TODO](TODO.md)

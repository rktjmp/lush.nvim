![Lush Header](../assets/images/header.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is aims to make colorscheme creation as painless as possible.

At its core, Lush presents your colorscheme as *structured data*, allowing you
to manipulate it in any way you want.

It comes with **as-you-edit feedback**, a selection of **color operation
helpers**, the ability for end users to **extend and configure colorschemes**,
as well an API to **export your colorscheme in any format**, including a
configurable lua colorscheme.

See some colorschemes [**Made with Lush**](made_with_lush/README.md#made-with-lush).

- [Annoucements](#annoucements)
- [Requirements](#requirements)
- [Installation](#installation)
- [Interative Tutorials](#interactive-tutorials)
- [Guides](#guides)
- [See Also](#see-also)

Annoucements
------------

- 2021-11-05: Deprecation warning, the compiler `exclude_keys` option has been
  deprecated in favour of the build system,
  - See [build guide](BUILD.md) for details.

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

- [Create your new colorscheme with lush-template (and how to import a non-lush colorscheme)](CREATE.md)
- [Extend an Lush existing colorscheme, or how users can configure your
  colorscheme](EXTEND.md)
- [Export your colorscheme to any format(s) with Shipwright](BUILD.md)
- [FAQ](FAQ.md)

See Also
--------

- [Vim Help](doc/lush.txt)
- [Change Log](CHANGELOG.md)
- [TODO](TODO.md)

![Lush Demo](images/demo.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is a color scheme creation aid, written in Lua, for Neovim.

Lush lets you define your scheme as a *mini-dsl*, provides HSL *colour
manipulation* aids, and gives you *real time* feedback of your changes.

Lush themes can be exported to plain VimL for distribution (or escape),
and they can also be *imported* to other Lua (or VimL) files to access color)
data.

**Lush is relatively stable and usable, but it still needs improvement. Some
aspects of the API may change.**

**See any [new changes](#change-log).**


Requirements
------------

- Neovim 0.5 or greater
- `termguicolors` enabled for true color support


Installation
------------

Install via any package management system, for example, vim-plug:

```vim
Plug 'rktjmp/lush.nvim'
```


Getting Started
---------------

There are two interactive tutorials provided,

- `:LushRunQuickstart` which will give you a few-minute overview of Lush's
  features. (`lush_quick_start.lua` in the examples folder.)

- `:LushRunTutorial`, a more in-depth guide through various ways to apply Lush.
  (`lush_tutorial.lua` in the examples folder).

A Lush theme template is available in the examples folder, as well as other
examples for various topics (Lightline, dependency injection, etc).


Usage
-----

Creating a color scheme in Lush is a three step process:

1. Define your colors using the HSL module
2. Define your highlight groups with a Lush spec
3. Organise your color scheme for normal usage and/or distribution

Along the way, you can use `:Lushify` to get live feedback on the appearance
of your color scheme.



### 1. Define your colors with the HSL module

HSL (Hue, Saturation, Lightness) is an alternative color representation to RGB.
In HSL, hue varies between 0 and 360 (like a color wheel),
and both saturation and lightness vary between 0 and 100.

The main advantage of HSL is that it allows you to create color palettes using very simple transformations.
For example, if you want to get the complement of a color, you rotate 180°.

```lua
local hsl = require('lush').hsl     -- Import and bind the HSL module
local red = hsl(0, 100, 50)         -- Define a simple red color
local complement = red.rotate(180)  -- Define the complement (i.e. cyan)
```

Note that cyan is also the complement of red in RGB: `(255, 0, 0)' == (0, 255, 255)`,
but using HSL only one value was modified.

Besides rotating hues, you can lighten or darken colors, and saturate or desaturate them.
Lush provides a comprehensive set of functions for this,
make sure to check out the the tutorial and the docs more details.



### 2. Define a lush-spec

After you've chosen your base colors, you can define a lush-spec.

A lush-spec is a Lua table where you define highlight groups with
their associated colors and decoration details.

The advantage of using a lush-spec is that you can define groups from previous groups,
and make modifications to easily define relational colors between groups.

For example, create a Lua file, and write this simple lush-spec:

```lua
-- require lush
local lush = require('lush')

-- lush() will parse the spec and
-- return a table containing all color information.
-- We return it for use in other files.
return lush(function()
  return {
    -- Define Vim's Normal highlight group
    Normal { bg = lush.hsl(208, 90, 30), fg = lush.hsl(208, 80, 80) },

    -- Make whitespace slightly darker than normal.
    -- you must define Normal before using it.
    Whitespace { fg = Normal.fg.darken(40) },

    -- Make comments look the same as whitespace, but with italic text
    Comment { Whitespace, gui="italic" },

    -- Clear all highlighting for CursorLine
    CursorLine { },
  }
end)
```

Now, run `:Lushify` to get live feedback on your lush-spec.
Remember to disable your LSP client and linters, these can interfere and
give a lot of false positives while using `:Lushify`.

One of the templates includes a list of all the highlight groups that (Neo)vim can use by default.
There's a lot, so defining simple relations between them is the best way to cover them all.



### 3. Organise your color scheme for distribution

There are two ways to use a color scheme created with Lush.
You can import it as a Lua module, or you can compile it to VimL.

In both cases the structure of your color scheme directory would look like this:
```
cool_name/
|-lua/
  |-lush_theme/
    |-cool_name.lua
|-colors/
  |-cool_name.vim
```


#### Using Lua

`cool_name.lua` would contain your lush-spec, as the one described above.
In `cool_name/colors/cool_name.vim` you would just require the Lua module,
that way, you can still set your color scheme with the `:colorscheme` command.

```vim
let g:colors_name="cool_name"
lua require('lush')(require('lush_theme.cool_name'))
```


#### Exporting to VimL

You can also compile your lush-spec to VimL, so you get backwards compatibility for free!

Running the following will open a new floating window with a list of highlight groups as defined in VimL.

```vim
:lua require('lush').export_to_buffer(require('lush_theme.cool_name'))
```

You can then yank the contents of the buffer, and paste it in `cool_name/colors/cool_name.vim`.
Remember to change `lush_theme.cool_name` to the name of the file where your lush-spec is defined.

Lush also provides functions to export your color scheme in a more automated way.
See the related documentation. <!-- link to parse-compile-apply -->

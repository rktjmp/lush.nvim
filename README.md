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

<!-- The two tutorials might get merged -->

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

1. Create your color scheme directory structure (or copy one from the templates)
2. Define your colors using the HSL module
3. Define your highlight groups with a Lush spec

Along the way, you can use `:Lushify` to get live feedback on the appereance
of your color scheme.

<!--
0. Create your color scheme directories...
Explain the directory structure of a color scheme: `lua/`, `colors/` etc.
-->

2. Define your colors with the HSL module

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
but with HSL only one value was modified.

2. Define a Lush-spec

After you've chosen your base colors, you can define a Lush spec.

```lua
-- in file cool_name/lua/lush_theme/cool_name.lua

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

Now in `cool_name/colors/cool_name.vim` you can write:

```vim
let g:colors_name="cool_name"

" you could check the `background` option,
" and require different files depending on its value (dark | light)

lua require('lush')(require('lush_theme.cool_name'))
```


********************

Table of Contents
-----------------

Lush broadly has 3 components,

- [A HSL color manipulator](#hsl-colors)
- The [lush-spec parser and compiler](#lush-spec)
  - The [lush-spec spec](#lush-spec-spec)
  - [Additional information](#additional-information) about lush-specs
- [Lush.ify](#lushify), a buffer highlighting and hot-reload tool

See also:

- [Todo / Future Ideas](#todo--future-ideas)
- [Change Log](#change-log)

For a usage example, see the quick start, tutorial and examples folder.

HSL Colors
----------

The [HSL color](https://www.w3.org/wiki/CSS3/Color/HSL) manipulator can be
accessed via `require('lush').hsl`.  It may also be included in other modules
via `require('lush.hsl')`.

You can create HSL colors by providing hue, saturation and lightness values,
or providing a hexadecimal string.

```lua
color = hsl(0, 100, 50) -- equivilent to rgb(255,0,0) elsewhere
hex_color = hsl("#FF0000") -- hex_color == color
```

It provides multiple methods for manipulating a color. All functions are pure,
always returning new colors and leaving the originals unmodified. Functions
can be chained.

There are 3 main operations you may want to perform:

- Rotate a hue.
- Saturate (or desaturate) a color.
- Lighten (or darken) a color.

Hue/rotate values are wrap around 0-360 degrees, lightness and saturation
are clamped between 0-100.

HSL provides the following functions to achieve these operations:

- `color.rotate(n)`: rotate `n` degrees around the color wheel.
  - `color.rotate(180)` gives you `color`'s complementary tone.
  - `color.rotate(40)` gives you an analogous color.
  - `color.rotate(-40)`, as above but in the opposite direction.
  - `color.rotate(120)` one part of the triad.
  - `color.rotate(-120)`, the other part of the triad.

- `color.saturate(n)`: increase a colors saturation by `n` percent.
  - `saturate` has a mirrored function, `desaturate`.
    - `saturate(-n) == desaturate(n)`

- `color.lighten(n)`: increase a colors lightness by `n` percent.
  - `lighten` has a mirrored function, `darken`.
    - `lighten(-n) == darken(n)`

Note that these functions are *relative* to the color space, not simply
additive. That is:

```lua
color = hsl(0, 50, 50)
color.saturate(10) -- adds 10% saturation to 50
```

If you wish to add an absolute amount to a color, you can use the `abs_`
prefixed functions (most of the time you should use relative adjustments):

- `color.abs_saturate(n)` (and `abs_desaturate`)
- `color.abs_lighten(n)` (and `abs_darken`)

Behaves as:

```lua
color = hsl(0, 50, 50)
color.abs_saturate(10) -- adds 10 to 50
```

Rotate does not have an `abs_` prefixed function, *it always operates
absolutely*.

All operations have shortcut aliases:

- `ro`: `rotate`
- `sa`: `saturate`
- `de`: `desaturate`
- `li`: `lighten`
- `da`: `darken`
- `abs_sa`: `abs_saturate`
- `abs_de`: `abs_desaturate`
- `abs_li`: `abs_lighten`
- `abs_da`: `abs_darken`

You may also directly set a HSL value via:

- `hue(n)`
- `saturation(n)`
- `lightness(n)`

And access members with,

- `color.h`: Hue.
- `color.s`: Saturation.
- `color.l`: Lightness.

Finally, HSL colors can be coerced into a hex string, either by:

- concatenation: `color .. "" == "#......"`
- `.hex` member: `color.hex == "#......"`
- `tostring(c)`: `tostring(color) == "#......"`

The following is an example of of all these concepts:

```lua
local hsl = require('lush').hsl                 -- include the module
local red = hsl(0, 100, 50)                     -- define a color
local light_red = red.lighten(20)               -- modify
local orange = red.hue(20)                      -- set
local sum_hues = red.h + light_red.h + orange.h -- access
local chained_compliment = red.ro(180)          -- chain via aliases
                              .da(30)
                              .sa(10)
print(red)                                      -- as string "#FF0000"
```

Lush Spec
---------

You define your color scheme by writing a lush-spec, which can leverage the
HSL module and be exported to other parts of Neovim. Lush will expose your
lush-spec as a Lua module.

The starter files, `examples/lush_quick_start.lua` and
`examples/lush_tutorial.lua` provide an interactive tutorial on how to create a
lush-spec.

The basic definition of a lush-spec is, a Lua table which defines your
highlight groups, by name, and their associated color and decoration details.

The advantage of using Lush and a lush-spec is that you're able to define
groups from previous groups, and make modifications on those groups to easily
define relational colours between groups.

If that sounded confusing, it's much simpler in practice.

Here's a very simple lush-spec:

```lua
-- cool_name/lua/lush_theme/cool_name.lua
-- require lush
local lush = require('lush')

-- lush(), when given a spec, will parse it and return a table 
-- containing your color information.
-- We should return it for use in other files.
return lush(function()
  return {
    -- Define what vims Normal highlight group should look like
    Normal { bg = lush.hsl(208, 90, 30), fg = lush.hsl(208, 80, 80) },
    -- And make whitespace slightly darker than normal.
    -- Note you must define Normal before you try to use it.
    Whitespace { fg = Normal.fg.darken(40) },
    -- And make comments look the same, but with italic text
    Comment { Whitespace, gui="italic" },
    -- and clear all highlighting for CursorLine
    CursorLine { },
  }
end)
```

```vim
" cool_name/colors/cool_name.vim
" yes, unfortunately you still have to write some VimL
set background=dark
let g:colors_name="cool_name"
" you could detect background == dark || light here and require
" different files
lua require('lush')(require('lush_theme.cool_name'))
```

That's essentially all you need to know to write a lush-spec. The starter
files provide a deeper example and some tips and tricks.

Lush-spec Spec
--------------

Lush supports the following group definitions:

**Direct Definition**

*Used to define a stand alone highlight group, see `:h highlight`.*

Supports the following keys:

- `fg`: sets the `guifg` property of a Vim highlight group.
- `bg`: sets the `guibg` property of a Vim highlight group.
- `gui`: sets the `gui` property of a Vim highlight group.
- `sp`: sets the `guisp` property of a Vim highlight group.
- `lush`: a namespace to save arbitrary data to a group. Is not exported to the
          final highlight but may be accessed in the lush-spec or the parsed-lush-spec.

Constraints:

- `value` may be any Lua type which will concatenate with a string.
- `value` may be derived from previously defined group properties.
- All unsupported keys are dropped.
- Group name is CamelCase by convention, but may be any string beginning with
- Group names may not be `ALL`, `NONE`, `ALLBUT`, `contained` or `contains`,
  this is a vim constraint.
  an alpha character.
- `font` key currently unsupported, create an issue if you would like to see this.

Syntax:

```lua
GroupName { fg = value, bg = value, gui = value, sp = value },
```

**Linked Group**

*Used to define a highlight link. see `:h hi-link`*

Supported keys:

N/A.

Constraints:

Linked group must be defined before the link definition.

Syntax:

```lua
LinkedGroup { GroupName },
```

**Inherited Group**

*Used to define a new highlight group, with properties inherited from another
group.*

This is logically similar to a *Linked Group*, except you wish to define new
keys, or redefine old keys.

Supported keys:

See *Direct Definition*.

Constraints:

- Only one parent group may be specified and it must be the first value in the
  group definition.
- Inherits constraints of *Direct Definition*

Syntax:

```lua
InheritedGroup { Parent, gui = "bold" },
```

Additional Information
----------------------

#### Performance

I, personally, would say there isn't a noticeable performance impact in using
Lush over a raw VimL colorscheme. The parse and compile stage is generally
around 1ms on my quite aged core i5 and is comparatively dwarfed by the 3ms
spent waiting Vim's interpreter to apply the commands, a penalty which raw VimL
schemes would share.

If you did feel the performance was poor, you can always export your theme to
VimL after using Lush to aid the development process.

*Times measured with libuv's hrtime(), specifically around the parse, compile
and apply calls. There may be a few extra nanoseconds not recorded between
calling in and out of functions, as well as the initial file load time
(which VimL would also incur).*

```
Parse:   286300  ns  0.2863 ms -- resolve lush-spec into concrete values
Compile: 671900  ns  0.6719 ms -- convert concrete spec into viml commands
Apply:   3134300 ns  3.1343 ms -- pass to VimL interpreter (iterate array and call "nvim_command", "nvim_exec" performance is identical)
Total:   4092500 ns  4.0925 ms

Parse:   373500  ns  0.3735 ms
Compile: 973400  ns  0.9734 ms
Apply:   3442400 ns  3.4424 ms
Total:   4789300 ns  4.7893 ms

Parse:   388700  ns  0.3887 ms
Compile: 705500  ns  0.7055 ms
Apply:   3446900 ns  3.4469 ms
Total:   4541100 ns  4.5411 ms

Parse:   299400  ns  0.2994 ms
Compile: 814600  ns  0.8146 ms
Apply:   3065300 ns  3.0653 ms
Total:   4179300 ns  4.1793 ms
```

#### Converting an Existing Theme to Lush

Currently there isn't an built in automated method for converting an
existing theme to Lush, but you can redirect all your current highlights to a
register, paste that into a buffer then construct some macros to reformat.

```vim
:redir @z
:highlight
" in buffer
"zp
```

#### Why `return ...`?

In the Lua file, we call `lush(lush-spec)`, which will parse the given
lush-spec, then it will return your theme as Lua a table (aka: a
parsed-lush-spec) You should return this table from your Lua theme file to
allow other modules to `require(a_lush_spec_file)` and access your themes
colour data.

In the vim file, we can call `lush(parsed-lush-spec)` to clear any existing
highlighting and apply our parsed lush-spec.

#### Why `lua/lush_theme/`?

Lua doesn't have any strict namespacing. Because anything in a plugins `lua/`
directory becomes available as a module in vim, it's advised to nest your
theme inside a `lush_theme` folder, essentially providing a namespace for all
lush themes to exist in. This is to avoid any collisions between themes and
other modules.

This isn't a strict rule enforced in anyway by Lush, simply a recommendation.

#### Why even do this? Seems like a lot of over engineering.

It's true that you could define most of your scheme with just regular Lua
variables, and maybe pass those in a map to some function to convert to
VimL commands, indeed that's how most Lua themes are made.

Really Lush started as a toy experiment in seeing how capable Lua was at making
DSLs, but it felt useful enough to me that other people might find it
interesting.

#### Linters

You will likely get warnings from linters while writing a lush-spec,
specifically around "undefined globals". Most of these warnings can be safely
ignored, you may wish to disable LSP/Linters temporarily when working on a
theme.

#### Dependency Injection (Why can't I access math.random?)

Lush-specs are executed a bare environment, so they don't have access to Lua
globals or other modules. However, they are also written as closures, so they
do have access to any local level variables in the theme file.

This means if you want to access a global module, you simply have to bind it
to a local scope variable.

```lua
-- all these local variables can be accessed in the spec closure
local weather = require('local_weather')
local harbour = require('lush_theme.harbour')
local math = math

lush(function()
  return {
    -- set fg color depending on rain or snow
    Normal  { fg = hsl(weather.hex_color_for_current_weather) },
    -- set comment color from normal fg, but set to a random
    -- analogous-ish color
    Comment { fg = Normal.fg.ro(math.random(-60, 60)) },
    -- we can even access other theme data
    -- automatic theme inheritance and extension is WIP
    CursorLine { fg =  harbour.CursorLine.fg, bg = harbour.CursorLine.bg },
  }
end)
```

#### Exporting From Lush

If you wish to move your theme away from lush, or export it for use in Vim,
you can run the following Lua code:

```vim
:lua require('lush').export_to_buffer(require('lua-module-theme-name'))
```

Your Lush theme will be exported to a new floating window, as a collection of
Vim highlight commands.

Note that the name you specify is the name of the Lua module in which your
theme was defined. In the above short-example, you would run

```vim
:lua require('lush').export_to_buffer(require('lush_theme.cool_name'))
```

#### Manual Toolchain

If desired, you can manually parse -> compile -> apply your lush-spec.

```lua
local lush = require('lush')
local parsed = lush.parse(function() return { ... } end)
local compiled = lush.compile(parsed, {force_clean = true })
lush.apply(compiled)
```

`compile` accepts a secondary `options` table with the following options:

- `force_clean`: `true` or `false`, prepends commands to clear and reset
  highlighting.

Lush.ify
-------

Lush.ify will provide automatic, real-time highlighting of any `hsl(...)` calls,
as well as highlighting any groups in your lush-spec with their appropriate
colors and decorations.

To use lush.ify, open your theme Lua file and run the vim command,

```vim
:Lushify
```

or run it directly via Lua,

```vim
:lua require('lush').ify()
```

Now changes you make to a colorscheme are reflected in real time. See the two
starter files for more information and a demonstration.

Performance of lush.ify is somewhat dependent on your hardware and probably
more specifically, your terminal. Some re-render faster than others.

Lush.ify will perform some minor event debouncing, with an increased window on
multiple parser failures. The defaults should allow for a smooth experience,
but if you desire to change them, you can pass options to lush.ify like so
(times are in ms),

```vim
:lua require('lush').ify({natural_timeout = 25, error_timeout = 300})
```

If you feel performance is poor, please try disabling any linter/lsp/etc first.

#### Lush.ify Incompatibilities

**Easy Motion**

Activating the easy motion plugin *in a lush.ify'd buffer* will cause a lot of
syntax errors. This is because easy-motion directly modifies the buffer to
display its "jump keys", which we try to parse.

It is not recommended you activate easy motion in a lush.ify'd buffer.

**Live Search-Replace**

If you use Neovim's live-updating search-and-replace feature (`:h inccommand`),
you may see Neovim errors being reported. In my experience these can be safely
ignored and you may continue as normal.

**Lightline**

While Lightline can be styled through Lush, real-time updating has some
caveats and performance may be less than optimal due to VimL performance.

See `examples/lightline-one-file` and `examples/lightline-two-files` for
guidance. Generally, if real time performance with Lightline is problematic,
I would recommend developing your theme first, then disabling lush.ify with
`:e!` in the buffer and applying your changes via `:luafile %`.

The two examples go into some more detail regarding this method.

Bugs or Limitations
-------------------

- Sometimes line group and HSL highlighting may appear out of sync if you've
  applied undo/redo chains to a lush.ify'd file. Generally typing more into the
  buffer will fix these issues as the highlighter re-syncs with the buffer
  state.

- You may find some elements don't update in real time (LSP sign column for
  example). This is a side effect of colours are applied to those elements,
  only as they are created (I believe).
  The group name in your lush-spec should update to let you see how it will
  look when your theme is loaded.

- Lush.ify'd `hsl()` and group name highlight may sometimes be obscured by
  CursorLine highlighting. If this is a problem, you can set CursorLine to an
  empty definition or disable the cursor line with `set nocursorline`.

Todo / Future ideas
-------------------

**Theme Inheritance**

This would give you the ability to require someone else's theme as a base to
yours.

Imagine you really like a theme, but wish the background was a bit different,
you could define your lush-spec with that theme as base/parent and just change
the groups you want.

I have a draft of this written but was unsure how useful it would really be as
a feature and if it was worth the work hours. Perhaps if Lush were popular this
more sense.

**Global HSL Shifting / Contrast Shifting?**

Unsure how useful this would be in the real world, but switching between some
machines can render some colourschemes differently, because their screens
or terminals are different.

The idea would be you could set a global shift on HSL to effect all colours
that are pushed through it.

In actuality, I think what I *really* want is a contrast scale, which isn't as
simple as simply "make it all brighter" or "make it all bluer".

**Automatic Property Inference**

Would allow for syntax like:

```lua
-- automatically infer appropriate key (Normal.fg)
CursorLine { fg = Normal, bg = Visual }
```

Most of this code is actually already present, but the ability to write
`fg = Normal` tends to encourage `fg = Normal.ro(...)` at a later time,
is an invalid operation.

Without a uniform solution to this, I'm reticent to "muddy" the API.

For now, you must write `fg = Normal.fg`.

Change Log
----------

- 2020-11-23
  - Lush.ify now reports errors in a more consistent format.
  - Lush.ify now rate-limits eval attempts on parsing errors.
- 2020-11-21
  - Lush-spec now supports group inheritance.
- 2020-11-19
  - Initial release.

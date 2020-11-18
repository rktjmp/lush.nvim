```
       ,gggg,
      d8" "8I                         ,dPYb,
      88  ,dP                         IP'`Yb
   8888888P"                          I8  8I
      88                              I8  8'
      88        gg      gg    ,g,     I8 dPgg,
 ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
 "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
```

Lush
====

Lush is a colorscheme creation plugin written in Lua, for Neovim.

Lush lets you define your scheme as a *mini-dsl*, provides HSL space *colour
manipulation* aids, and gives you *real time* feedback of your changes.

Lush themes can be exported to plain vimscript for distribution (or escape),
and they can also be *imported* to other lua/vimscript files to access color
data.

Installation and Getting Started
--------------------------------

Lush is:

  - **Neovim only**
  - requires **0.5.0** or greater.
  - "true color" only

Install via any package mangement system, for example, vim-plug:

```vim
Plug 'rktjmp/lush.nvim'
```

There are two interactive tutorials provided,

- `lush_quick_start.lua`, which will give you a 2 minute overview of Lush's
  features

- `lush_tutorial.lua`, a more in-depth guide through various ways to apply
  lush.

There are also examples of various topics (lightline, import, export) in the
`examples` folder.

Component Guide
---------------

Lush broadly has 3 components,

- A HSL color manipulator,
- The lush-spec parser and compiler, and
- Lushify, a buffer highlighting and hot-reload tool.

For a usage example, 

HSL Colors
----------

The [HSL color](https://www.w3.org/wiki/CSS3/Color/HSL) manipulator can be
accessed via `require('lush').hsl`.  It may also be included in other modules
via `require('lush.hsl')`.

You can create HSL colors by providing hue, saturation and lightness values,
or providing a hexidecimal string.

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

Hue/rotate values are wrapped around 0-360 degrees, lightness and saturations
are between 0-100.

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
prefixed functions (most of the time you should use relative ajustments):

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
HSL module and be exported to other parts of Neovim.

The starter files, `lush_quick_start.lua` and `lush_tutorial.lua` provide an
interactive tutorial on how to create a lush-spec.

The basic definition of a lush-spec is, a lua table which defines your
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
    -- And make our comments slightly darker than normal, in italics
    Comment { fg = Normal.darken(40), gui = "italic" },
    -- And make Whitespace look the same
    Whitespace { Comment },
  }
end)
```

```vim
" cool_name/colors/cool_name.vim
" yes, unfortunately you still have to write some vimscript
set background=dark
let g:colors_name="cool_name"
" you could detect background == dark || light here and require
" different files
lua require('lush')(require('lush_theme.cool_name'))
```

That's essentially all you need to know to write a lush-spec. The starter
files provide a deeper example and some tips and tricks.

#### Why `return ...`?

In the lua file, we call `lush(lush-spec)`, which will parse the given
lush-spec, then it will return your theme as lua a table (aka: a
parsed-lush-spec) You should return this table from your lua theme file to
allow other modules to `require(a_lush_spec_file)` and access your themes
colour data.

In the vim file, we can call `lush(parsed-lush-spec)` to clear any existing
highlighting and apply our parsed lush-spec.

#### Linters

You will likely get warnings from linters while writing a lush-spec,
specifally around "undefined globals". Most of these warnings can be safely
ignored, you may wish to disable LSP/Linters temporarily when working on a
theme.

#### Reserved names

You may not name any groups `ALL`, `NONE`, `ALLBUT`, `contained` or `contains`,
this is a vim constraint.

Lush.ify
-------

Lush.ify will provide automatic, realtime highlighting of any hsl(...) calls,
as well as highlighting any groups in your lush-spec with their appropriate
colors.

To use lushify, open your theme lua file and run

```vim
:lua require('lush').ify()
```

#TODO Lushify's convenience method is limited to one buffer at a time (the last it
was attached to), but you may call `attach_to_buffer(buffer_number)` manually
if you desire.

Notes
---

You can use HSL anywhere, (require('lush').hsl, access h,s,l values via h,s or
l and convert to hex via tostring() or concat. Similarly lush.ify() will work
in any buffer you attach it to (hsl(...) should be compatible, groups may
highlight odd things depending on the file).

bg, fg, gui = "bold, italic", sp = "NONE"

HSL can be coerced into hex by tostring() or concat, so you can use those
colors in raw commands if you need to.

Common usage might be to get a color and find its triad(s) (rotate(120),
rotate(240)) or it's complement (rotate(180)), or split complement
(rotate(180).rotate(between -30 and 30))

Bugs or Limitations
---

- you may find some elements don't update in real time (LSP sign column for example). This is a side effect of colours are applied to those elements, only as they are created. The group name in your lush-spec should update to let you see how it will look when your theme is loaded.

- Sometimes real time highlighting be applied awkwardly when the Pmenu is open.

- you cant name groups NONE ALL contains contained ALLBUT (reserved by vim)

- Maybe you want to link to an existing group not in spec? See signify-colors
  linking to DiffText.
- maybe you want to define a color type mid stream? Can do this with a 'fake'
  that doesn't actually have a match group,but you can then reference as a var

- HSL() and Group colors may be invisible if your cursor line settings are strong
- HSL highlights multiple times on one line

u
(set a bg or fg).

- lush.ify() real time updates are limited to one buffer at a time.

- You must define all elements you want to reference, i.e.

  Task { Todo }

will fail, because Todo, though it's a standard group name, doesn't exist in lush.

  Todo { bg = ... }
  Task { Todo }

will work.

- If you're using a lua LSP, you may see warnings (ignorable), and it may style some groups (underline or color) depending on how agressive it's behaviour is.





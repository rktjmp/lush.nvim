
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

    Plug 'rktjmp/lush.nvim'

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

**HSL colors**

The [HSL color](https://www.w3.org/wiki/CSS3/Color/HSL) manipulator can be
accessed via `require('lush').hsl`.  It may also be included in other modules
via `require('lush.hsl')`.

You can create HSL colors by providing hue, saturation and lightness values,
or providing a hexidecimal string.

    color = hsl(0, 100, 50) -- equivilent to rgb(255,0,0) elsewhere
    hex_color = hsl("#FF0000") -- hex_color == color

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

    color = hsl(0, 50, 50)
    color.saturate(10) -- adds 10% saturation to 50

If you wish to add an absolute amount to a color, you can use the `abs_`
prefixed functions (most of the time you should use relative ajustments):

- `color.abs_saturate(n)` (and `abs_desaturate`)
- `color.abs_lighten(n)` (and `abs_darken`)

Behaves as:

    color = hsl(0, 50, 50)
    color.abs_saturate(10) -- adds 10 to 50

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

    local hsl = require('lush').hsl                 -- include the module
    local red = hsl(0, 100, 50)                     -- define a color
    local light_red = red.lighten(20)               -- modify
    local orange = red.hue(20)                      -- set
    local sum_hues = red.h + light_red.h + orange.h -- access
    local chained_compliment = red.ro(180)          -- chain via aliases
                                  .da(30)
                                  .sa(10)
    print(red)                                      -- as string (#hex)

**Lush Spec**

You define your color scheme by writing a lush-spec.

    local lush = require('lush')
    lush(function()
      return {
        -- your spec goes here
        -- define a group
        Normal { bg = lush.hsl(...), fg = ...},
        -- you can also provide gui and sp options as strings
        -- link a group
        NormalFloat { Normal },
        -- compose a group from another
        CursorLine { bg = Normal.bg.lighten(10) },
      }
    end)

See the starter file for a more complete example.

You will likely get warnings from linters while writing a lush-spec, so you may
want to disable them for your scheme buffer.

You may not name any groups `ALL`, `NONE`, `ALLBUT`, `contained` or `contains`,
this is a vim constraint.

**Lushify**

Lushify will provide automatic, realtime highlighting of any hsl(...) calls, as
well as highlighting any groups in your lush-spec with their appropriate colors.

To use lushify, open your theme lua file and run

    :lua require('lush').ify()

Lushify's convenience method is limited to one buffer at a time (the last it was attached to), but you may call `attach_to_buffer(buffer_number)` manually if you desire.

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





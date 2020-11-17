
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

Lush is a neovim colorscheme creation plugin.

Lush lets you define your scheme as a mini-dsl), as well as providing some
helpers for HSL color manipulation and live updating as you work
on your theme (well, semi-live, post-write updating).

Demo
-----

View the demo, or read on.

Installation
------------

Lush is:

  - **neovim only**
  - requires **0.5.0** or greater.
  - true color only

Install via any package mangement system, for example, vim-plug:

    Plug 'rktjmp/lush.nvim'

A sample lush-spec theme is provided at ..., copy this to your theme's lua folder
to get started.

Components
----------

Lush broadly has 3 components, a HSL color manipulator, the lush-spec parser
and compiler; and lushify, a buffer highlighting and hotreload tool.

For a usage example, 

**HSL colors**

The HSL color manipulator can be accessed via `require('lush').hsl`. It may be
included in other modules via `require('lush.hsl')`.

It provides multiple methods for manipulating a color. All functions are pure
and return new colors.

Hue/rotate values are wrapped around 0-360 degrees, lightness and saturations
are between 0-100.

    local hsl = require('lush').hsl                 -- include the module
    local red = hsl(0, 100, 50)                     -- define a color
    local light_red = red.lighten(20)               -- modify
    local orange = red.hue(20)                      -- set
    local sum_reds = red.h + light_red.h + orange.h -- access
    local chained_compliment = red.rotate(180)      -- chain
                                  .darken(30)
                                  .saturate(10)
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





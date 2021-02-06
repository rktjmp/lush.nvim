![Lush Demo](images/demo.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is a color scheme creation aid, written in Lua, for Neovim.

Lush lets you define your scheme as a *mini-dsl*, provides HSL *colour
manipulation* aids, and gives you *real time* feedback of your changes.

Lush themes can be exported to plain VimL for distribution (or escape),
and they can also be *imported* to other Lua (or VimL) files to access color)
data.


Requirements
------------

- Neovim 0.5 or greater
- `termguicolors` enabled for true color support


Installation
------------

Install via any package management system, for example, paq:

```vim
paq 'rktjmp/lush.nvim'
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

To create a Vim colorscheme in Lush,

1. Create your lush-template directory
2. Define your colors using the HSL module
3. Define your highlight groups with a Lush spec
4. (optional) Export your colorscheme for distribution to non-Neovim clients.

The `:Lushify` command can be used during development for real time feedback on the appearance of your color scheme.


### 1. Create your lush-template directory

Either fork or clone the repo at [rktjmp/lush-template](https://github.com/rktjmp/lush-template), then rename two files to match your theme name. You can automate this with the commands below (bash/zsh compatible).

First, set your lush theme name. Don't worry, you can change it later.

```
export LUSH_NAME=<your lush theme name>
```

Then run the setup script:

```
git clone git@github.com:rktjmp/lush-template.git $LUSH_NAME
cd $LUSH_NAME
mv colors/lush_template.vim colors/$LUSH_NAME.vim
mv lua/lush_theme/lush_template.lua lua/lush_theme/$LUSH_NAME.lua
if command -v sed &> /dev/null then
  sed -i 's/lush_template/$LUSH_NAME/g' lua/lush_theme/$LUSH_NAME.vim
else
  echo "Could not find sed, manually replace 'lush_template' with '$LUSH_NAME' in colors/$LUSH_NAME.vim"
fi
```

Your lush theme will have two sub-directories:
 
- `lua`: where you'll put your lush-spec file.
- `colors`: where you write a small VimL file that's read by Neovim when setting 
`:colorscheme`.

As an example:

```sh
cool_name/
|-lua/
  |-lush_theme/
    |-cool_name.lua # Your lush spec goes here
|-colors/
  |-cool_name.vim
```

### 2. Define your colors with the HSL module

HSL (Hue, Saturation, Lightness) is an alternative color representation to RGB.
In HSL, hue varies between 0 and 360 — like a color wheel,
and both saturation and lightness vary between 0 and 100 —like percentages.

The main advantage of HSL is that it allows you to create color palettes using simple, easy to reckon transformations.

For example, if you want to get the complement of a color, you rotate 180°.

```lua
local hsl = require('lush').hsl     -- Import and bind the HSL module
local red = hsl(0, 100, 50)         -- Define a simple red color
local complement = red.rotate(180)  -- Define the complement (i.e. cyan)
```

Note that cyan is also the complement of red in RGB:
red is `(255, 0, 0)` and cyan `(0, 255, 255)`,
but using HSL only one value was modified.


If you wanted a monochromatic palette, you can darken a color multiple times:

```
local red = hsl(0, 100, 50)
local dark_red = red.darken(30)
local dusk_red = red.darken(60)
```

Lush provides a comprehensive set of functions to work with HSL colors. You can rotate hues, lighten or darken colors, and saturate or desaturate them.

Be sure to check out the the tutorial (`:LushRunTutorial`) and the [docs (:h lush)](doc/lush.txt) more details.


### 3. Define a lush-spec

After you've chosen your base colors, you can define a lush-spec.

A lush-spec is a Lua table where you define highlight groups with
their associated colors and decoration details.
The advantage of using a lush-spec is that you can define groups from previous groups,
and make modifications to easily define relational colors between groups.

A simple Lush spec would look like this:

```lua
-- In cool_name/lua/lush_theme/cool_name.lua

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

One of the templates includes a list of all the highlight groups that Neovim uses by default.
There's a lot, so defining simple relations between them is the best way to cover them all.



### 4. (optional) Compile to VimL

If you want to, you can also compile your lush-spec to VimL,
so you get backwards compatibility with Vim8 for free!

Running the following will open a new floating window with a
list of highlight groups as defined in VimL.

```vim
:lua require('lush').export_to_buffer(require('lush_theme.cool_name'))
```

You can then yank the contents of the buffer, and paste it in `cool_name/colors/cool_name.vim`.

Lush also provides functions to export your color scheme in a more automated way.
See the related documentation. <!-- link to parse-compile-apply -->




QA
--

#### Is Lush slow?

Short answer: no.

Long answer:

There isn't a noticeable performance impact in using Lush over a raw VimL colorscheme.
The parse and compile stage is generally around 1ms on a quite aged core i5 and
is comparatively dwarfed by the 3ms spent waiting Vim's interpreter to apply the commands,
a penalty which raw VimL schemes would share.

If you noticed a poor performance, you can always export your theme to
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


#### Why `return ...`?

In Lua modules are just tables.
Calling `lush(lush-spec)` will parse the given lush-spec,
then it will return your theme as a Lua table (i.e. a parsed-lush-spec).
Returning this table allows other modules to `require(lush_spec_file)`
and access your color scheme data.

In the VimL file, we can call `lush(parsed-lush-spec)` to clear any existing
highlighting and apply our parsed lush-spec.

#### Why `lua/lush_theme/`?

Lua doesn't have any strict namespacing. Anything in a plugin's `lua/`
directory becomes available as a module in Vim, so it's advised to nest your
theme inside a `lush_theme` folder, providing a namespace for all
lush themes. This is to avoid any collisions between themes and
other modules.

This isn't a strict rule enforced in any way by Lush, simply a recommendation.

#### Why even do this? Seems like a lot of over engineering.

It's true that you could define your color scheme with just regular Lua
variables, and maybe pass those in a map to some function to convert to
VimL commands, indeed that's how most Lua themes are made.

Really Lush started as a toy experiment in seeing how capable Lua was at making
DSLs, but it felt useful enough to me that other people might find it
interesting.

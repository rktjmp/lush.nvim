![Lush Header](../assets/images/header.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is a colorscheme creation aid, written in Lua, for Neovim.

- [x] [Real time feedback!](#getting-started)
- [x] [HSL color aids!](#2-create-your-theme)
- [x] [HSLuv Support!](https://www.hsluv.org/)
- [x] [Lua fast!](#is-lush-slow)
- [x] Easily [extend](#advanced-example) other [themes!](made_with_lush/README.md#made-with-lush)
- [x] Export to [Vim](#4-optional-export-your-theme-for-distribution-to-non-neovim-clients) or [other tools!](#using-lush-data-elsewhere)

See some themes [**Made with Lush**](made_with_lush/README.md#made-with-lush).

Requirements
------------

- Neovim 0.5 or greater
  - (themes can be exported for Vim compatibilty)
- `termguicolors` enabled for true color support

Installation
------------

Install via any package management system, for example, paq:

```vim
require paq { 'rktjmp/lush.nvim' }
```


Getting Started
---------------

![Lush Demo](../assets/images/demo.gif)

There are two interactive tutorials provided,

- `:LushRunQuickstart` which will give you a few-minute overview of Lush's
  features. (`lush_quick_start.lua` in the examples folder.)

- `:LushRunTutorial`, a more in-depth guide through various ways to apply Lush.
  (`lush_tutorial.lua` in the examples folder).

Usage
-----

To create a Vim colorscheme in Lush,

1. Copy the lush-template
2. Create your theme
3. Add your theme to nvim
4. (optional) Export your theme for distribution to non-Neovim clients.

The `:Lushify` command can be used during development for real time feedback on
the appearance of your colorscheme.

See also, Advanced Usage and `:h lush` for more detailed documentation.

### 1. Copy the lush-template

Either fork, clone or recreate the repo at
[rktjmp/lush-template](https://github.com/rktjmp/lush-template), then rename
two files to match your theme name. You can automate this with the commands
below (bash/zsh compatible).

First, clone down a copy of the template, picking a name for your theme; don't
worry, it's easy to change this later.

```sh
git clone git@github.com:rktjmp/lush-template.git <your_theme_name>
cd <your_theme_name>
```

Then run the setup script:

```sh
sh << "EOF"
  git reset --soft 9069669
  git add .
  git commit --amend --no-edit
  LUSH_NAME=$(basename $(pwd))
  GIT_NAME=$(git config user.name)
  YEAR=$(date +"%Y")
  mv colors/lush_template.vim colors/$LUSH_NAME.vim
  mv lua/lush_theme/lush_template.lua lua/lush_theme/$LUSH_NAME.lua
  if command -v sed &> /dev/null; then
    sed -i "s/lush_template/$LUSH_NAME/g" colors/$LUSH_NAME.vim
    sed -i "s/COPYRIGHT_NAME/$GIT_NAME/g" LICENSE
    sed -i "s/COPYRIGHT_YEAR/$YEAR/g" LICENSE
    git add .
    git commit -m "Configure template for $LUSH_NAME, please enjoy using Lush!"
  else
    echo "Could not find sed, please manually replace 'lush_template' with '$LUSH_NAME' in colors/$LUSH_NAME.vim, and update the LICENCE file."
  fi
EOF
```

A lush theme has the following directory structure:

```
cool_name/
|-lua/
  |-lush_theme/
    |-cool_name.lua # contains your lush spec
|-colors/
  |-cool_name.vim   # exposes your lush theme to neovim
```

### 2. Create your theme

Open your `lua/lush_theme/*.lua` file, run `:Lushify` and create your lush-spec.

Remember you can define relationships between highlight groups, which makes it
easy to work with color variations within a theme.

Be sure to check out the the tutorial if you haven't yet (`:LushRunTutorial`)
or see the [docs (:h lush)](doc/lush.txt) more details.

You may prefer to disable LSP/Linters while editing your lush spec, as they can
have trouble parsing the meta programming, or disable `undefined global` warninngs
if your LSP supports annotations. For example, sumneko's lua-language-server accepts:

```lua
---@diagnostic disable: undefined-global
local theme = lush(function()
-- your theme here...
```

The examples folder contains various examples for topics like Lightline or
dependency injection.

A simple lush-spec would look like this:

```lua
-- In cool_name/lua/lush_theme/cool_name.lua

-- require lush
local lush = require('lush')
locah hsl = lush.hsl

-- lush() will parse the spec and
-- return a table containing all color information.
-- We return it for use in other files.
return lush(function()
  return {
    -- Define Vim's Normal highlight group
    Normal { bg = hsl(208, 90, 30), fg = hsl(208, 80, 80) },

    -- Make whitespace slightly darker than normal.
    -- you must define Normal before deriving from it.
    Whitespace { fg = Normal.fg.darken(40) },

    -- Make comments look the same as whitespace, but with italic text
    Comment { Whitespace, gui="italic" },

    -- Clear all highlighting for CursorLine
    CursorLine { },
  }
end)
```

### 3. Add your theme to nvim

Lush themes (like most vim colorschemes) act as plugins, so we have to add our
theme to neovim's runtime before we can load it. Most people will do this via
a package manager.

Assuming your theme is in `~/projects/cool_name`:

```lua
-- when using packer-nvim
use '~/projects/cool_name'
```

```viml
" when using vim-plug
Plug '~/projects/cool_name'
```

Afterwards we can apply the theme like any other:

```viml
colorscheme cool_name
```

### 4. (optional) Export your theme for distribution to non-Neovim clients.

If you want to, you can also compile your completed theme to VimL. This is only
required if you want your theme to be compatible with Vim.

Running the following will open a new floating window with a
list of highlight groups as defined in VimL.

```vim
:lua require('lush').export_to_buffer(require('lush_theme.cool_name'))
```

You can then yank the contents of the buffer, and paste it in
`cool_name/colors/cool_name.vim`.

**Important Warning**

Vim does not support the `blend` property, and so if you intend to export to Vim
you will have to 1) not use blend and 2) filter out `blend=NONE` in the exported file.

A method to ease this is forthcomming, see [#29](https://github.com/rktjmp/lush.nvim/issues/29) and [#30](https://github.com/rktjmp/lush.nvim/issues/30).

Advanced Usage
--------------

### Spec Extension and Merging

Lush provides two methods for extending existing lush themes,
`lush.extends({parsed_spec, ...}).with(spec)` and
`lush.merge({parsed_spec, ...})`.

Potential reasons you may wish to extend a spec:

- You like a lush theme you got online, but want to change a few specific
  parts of it, such as the comment style, or the background color.

- You want to add a plugin to an theme by using it's existing groups.

- You are writing your own theme and want to make a small tweaks to create a
  variant, for example a high-contrast or colorblind safe mode.

Potential reasons you may wish to merge specs:

- You have a collection of plugin highlight groups want to let users configure
  which highlight groups are enabled.

- You want to apply a patch/extension to a theme that isn't provided by the
  main theme repo.

- You simply want to define your theme in parts for maintenance reasons.

For more detailed usage and examples, see `:h lush-extending-specs`.

An example of adding missing plugin support:

#### Advanced Example

```lua
local lush = require('lush')
local hsl = lush.hsl

-- some theme from the internet
local harbour = require('lush_theme.harbour')

local spec = lush.extends({harbour}).with(function()
  return {
    -- make Sneak look like Search
    Sneak { harbour.Search },
    -- you can now use Sneak just like any other group (ref, inherit, etc)
    SneakScope { bg = Sneak.bg.li(10) },
    SneakLabel { Sneak, gui = "italic" },
    -- you can use bits from anywhere
    MixAndMatch { bg = harbour.Normal.fg, fg = SneakLabel.fg, gui = "underline" },
  }
end)

return spec
```

### Using Lush Data Elsewhere

Every Lush theme is a compiled down to a Lua table. This lets you import it into
other Lua modules or into other themes.

An demonstration of this is shown in the examples folder, where a parsed lush
spec is used to set the lightline theme, or above when using `extends`.

Another example can be seen in [savq/melange](https://github.com/savq/melange),
where the parsed lush spec is used to generate an Alacritty terminal theme. You
could extend this concept into generating colors for your diff tool, css code
blocks, etc.

Or, using your nvim theme as a base for your AwesomeWM theme:

```lua
-- add lush lush and lush theme to lua path
package.path = package.path
                .. ";/home/user/.local/share/nvim/site/plugged/lush.nvim/lua/?.lua"
                .. ";/home/user/.local/share/nvim/site/plugged/lush.nvim/lua/?/?.lua"
                .. ";/home/user/.local/share/nvim/site/plugged/lush-olive-tree/lua/?/?.lua"
-- require lush theme
local olive_tree = require("lush_theme.olive_tree")

-- use lush theme in awesomewm sheme
theme.bg_normal     = olive_tree.SignColumn.bg.hex
theme.bg_error      = olive_tree.Warning.bg.li(30).hex
```

Q/A
---

#### Lush is too magical, will I get burned?

Meta programming can be scary. It can be confusing to reason with and can be
very infrutrating to debug when something goes wrong "inside the box".

Maybe like all good magic tricks, Lush *looks* a lot more magical than it
really is.

The metaprogramming is really only in the parser, and this is where you write a
very strict subset of instructions (group names, fg, bg, etc).

As long as your spec is valid lua code (correct braces, commas, closing
quotation marks, no spurious characters, etc), there shouldn't be a steep
learning curve or much to actually debug. All you're really doing is writing a
Lua table.

```lua
-- no magic zone
-- anything you do here is just plain old regular lua
local ten = 8 + 2

local spec = lush(function ()
  return {
    -- ~*~ some magic zone ~*~
    -- here we are defining our DSL, some magic required, no magic "leaks" out.

    Normal { fg = "red", bg = hsl(200, 40, 20) },
--  ^      ^                  ^ no magic, just returns a lua table with functions attached
--  |      | just a lua table, no magic
--  | some magic to used to turn function call Normal({...}) into table key Normal = {...}

    CursorLine { fg = Normal.fg.da(10) },
--                    ^ no magic, just a table lookup

    Comment { Normal, fg = "blue" }
--            ^ no magic, just copying one table to another
  }
end)

-- no magic zone
-- returned parsed spec is just a lua table, it has no special magic attached
-- and you can work with it like any other lua table: delete keys, copy values
-- transform values, write to json, etc.

local normal_fg = spec.Normal.fg
--                ^    ^      ^ just a table with functions attached
--                |    | just a table
--                | just a table
```

Similarly in your `color/.vim` file,

```lua
-- no magic zone
local parsed_spec = require('lush_theme.theme') 
--    ^             ^ no magic, just a normal lua module
--    | just a table
lush(parsed_spec)
--   ^ just an if check for table or function and either parses or applies the
--     theme the compiler just iterates over the spec (which is just a table)
--     and interpolates the values into some strings which get sent to vim to
--     interpret.
```

`:Lushify` is also pretty non-magic. It just reads the current buffer, sends it
to the lua interpreter, hoping to get back a parsed lush spec, and then calls
`compile` and `apply` in the background.

#### Why `return ...`?

By returning our theme it acts as a Lua module, which allows us to use it in
other Lua code or other themes.

When we call `lush(lush-spec)` in our `.lua` file, our lush-spec is parsed and
returned as a Lua table, we call this a "parsed-lush-spec". We then `return`
this table at the end of the file.

The parsed-lush-spec can be passed to lush to *apply* the spec (as seen in the
`.vim` file), but by returning the parsed-lush-spec, we can also require the
lush-spec in other Lua code (`require('lush_theme.cool_name')`) and access it's
color values.

#### Why `lua/lush_theme/`?

Lua doesn't have any strict namespacing. Anything in a plugin's `lua/`
directory becomes available as a module in Vim, so it's advised to nest your
theme inside a `lush_theme` folder, providing a namespace for all
lush themes. This is to avoid any collisions between themes and
other modules.

This isn't a strict rule enforced in any way by Lush, simply a recommendation.

#### Is Lush slow?

Short answer: no.

Long answer:

There isn't a noticeable performance impact in using Lush over a raw VimL
colorscheme.  The parse and compile stage is generally around 1ms on a quite
aged core i5 and is comparatively dwarfed by the 3ms spent waiting Vim's
interpreter to apply the commands, a penalty which raw VimL schemes would
share.

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

See also [issue #19](https://github.com/rktjmp/lush.nvim/issues/19), where
1000, 2000 and 4000 rule specs were tested. VimL is stll consistently the
bottleneck.

Note that a 1000 rule spec is likely pretty unsual. There are only about 150
base groups provided by Neovim and most plugins only provide another 5-10 (or
less).

A 4k rule spec would probably mean you're loading an enourmous number of
plugins, at which point your load times are probably also already enormous.

Also as per the issue, since VimL is such a huge bottleneck, you may find
similarly sized colorschemes actually load *faster* via Lush because any maths
and manipulation is done via Lua instead.

```
1k rules
--------
parse time:    4095342 ns,  4.095342 ms
compile time:   863515 ns,  0.863515 ms
apply time:   13150290 ns, 13.150290 ms

2k rules
--------
parse time:    8310824 ns,  8.310824 ms
compile time:  1791501 ns,  1.791501 ms
apply time:   34649903 ns, 34.649903 ms

4k rules
--------
parse time:   15170685 ns, 15.170685 ms
compile time:  6865722 ns,  6.865722 ms
apply time:   82630480 ns, 82.630480 ms
```

See Also
--------

- [Vim Help](doc/lush.txt)
- [Change Log](CHANGELOG.md)
- [TODO](TODO.md)


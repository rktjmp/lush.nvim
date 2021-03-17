![Lush Header](images/header.gif)

Lush ![CI](https://github.com/rktjmp/lush.nvim/workflows/CI/badge.svg)
====

Lush is a colorscheme creation aid, written in Lua, for Neovim.

Lush lets you define your scheme as a *mini-dsl*, provides HSL *colour
manipulation* aids, and gives you *real time* feedback of your changes.

Lush themes can be exported to plain VimL for distribution (or escape),
and they can also be *imported* to other Lua (or VimL) files to access color)
data.


Requirements
------------

- Neovim 0.5 or greater
  - (themes can be exported for Vim compatibilty)
- `termguicolors` enabled for true color support

Installation
------------

Install via any package management system, for example, paq:

```vim
paq 'rktjmp/lush.nvim'
```


Getting Started
---------------

![Lush Demo](images/demo.gif)

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
3. (optional) Export your theme for distribution to non-Neovim clients.

The `:Lushify` command can be used during development for real time feedback on
the appearance of your colorscheme.


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
have trouble parsing the meta programming. The examples folder contains various
examples for topics like Lightline or dependency injection.

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

### 3. (optional) Export your theme for distribution to non-Neovim clients.

If you want to, you can also compile your completed theme to VimL. This is only
required if you want your theme to be compatible with Vim.

Running the following will open a new floating window with a
list of highlight groups as defined in VimL.

```vim
:lua require('lush').export_to_buffer(require('lush_theme.cool_name'))
```

You can then yank the contents of the buffer, and paste it in
`cool_name/colors/cool_name.vim`.

Q/A
---

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


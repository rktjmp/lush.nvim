Extending a Lush Colorscheme
============================

Lush allows you access to your coloscheme in a formalised data structure. This
lets us manipulate it easily by using lush itself or any lua code.

- [Extend and merge](#extend-and-merge)
- [Configuring a colorscheme as an end-user](#configuring-a-colorscheme-as-an-end-user)
- [Adding support for a plugin](#adding-support-for-a-plugin)
- [Combining specs to create a variation](#combining-specs-to-create-a-variation)
- [Using Lush data anywhere](#using-lush-data-anywhere)

## `extend` and `merge`

Lush provides two methods to easly extend existing Lush coloschemes:

- `lush.extend({parsed_spec, ...}).with(spec)` is mostly directed at end-users
who wish to modify an existing colorscheme, though it can be used in a similar style
to `lush.merge()`. `lush.extend().with()` also allows developers to provide
"configuration" of their colorscheme without any extra effort as *everything* is user
configurable.

- `lush.merge({parsed_spec, ...})` simply applies each spec over the last, in
order, which is useful if you have large "base colorscheme", and a smaller set of
variations you wish to apply as overrides.

Potential uses cases for `lush.extends().with()`:

- You like a lush colorscheme you got online, but want to change a few specific
  parts of it, such as the comment style, or the background color.
- You want to add a plugin to an colorscheme by using it's existing groups.
- You are writing your own colorscheme and want to make a small tweaks to create a
  variant, for example a high-contrast or colorblind safe mode.

Potential use cases for `lush.merge()`:

- You have a collection of plugin highlight groups want to let users configure
  which highlight groups are enabled.
- You want to apply a patch/extension to a colorscheme that isn't provided by the
  main colorscheme repo.
- You simply want to define your colorscheme in parts for maintenance reasons.

For more detailed usage and examples, see `:h lush-extending-specs`.

## Configuring a colorscheme as an end-user

This requires:

- The colorscheme be distributed/available as a lua module
- The user has Lush installed

In this example, we will apply a common configuration option: comments in italic.

The following lua can be placed anywhere in your nvim init, you do not have
explicitly create a colorscheme to apply the modification, though you of course
could.

```lua
-- First we will need lush, and the colorscheme we wish to modify
local lush = require('lush')
local harbour = require('lush_colorscheme.harbour')

-- we can apply modifications ontop of the existing colorscheme
local spec = lush.extends({harbour}).with(function()
  return {
    -- Use the existing Comment group in harbour, but adjust the gui attribute
    Comment { fg = harbour.Comment.fg, bg = harbour.Comment.bg, gui = "italic" },
    -- While we're here, we might decide that the default Function group is too bright
    Function { fg = harbour.Function.fg.da(10) }
  }
end)

-- You may prefer to put this in its own module, shown on _G for brevity.
_G.customise_colorscheme = function()
  -- now we can apply the modified spec.
  lush(spec)
end
```

```vimscript
autocmd VimEnter,ColorScheme * lua customise_colorscheme()
```

## Adding support for a plugin

This requires:

- The colorscheme be distributed/available as a lua module
- The user has Lush installed

In this example, we will add (or modify) a highlight group for a plugin that is
not natively supported by an existing colorscheme. We will use some existing
highlight groups so our plugin integrates with the colorscheme naturally.

The following lua can be placed anywhere in your nvim init, you do not have
explicitly create a colorscheme to apply the modification, though you of course
could.

```lua
-- First we will need lush, and the colorscheme we wish to modify
local lush = require('lush')
local harbour = require('lush_colorscheme.harbour')

-- Now we will extend the colorscheme
local spec = lush.extends({harbour}).with(function()
  return {
    -- make the telescope popup look like the pmenu
    TelescopeNormal { harbour.Pmenu },
    -- you can now use TelescopeNormal just like any other group (ref, inherit, etc)
    TelescopeBorder { fg = TelescopeNormal.bg.li(20) },
    TelescopeTitle { fg = TelescopeNormal.bg, bg = TelescopeNormal.fg },
  }
end)

-- You may prefer to put this in its own module, shown on _G for brevity.
_G.customise_colorscheme = function()
  lush(spec)
end
```

```vimscript
autocmd VimEnter,ColorScheme * lua customise_colorscheme()
```

## Combining specs to create a variation

You can apply the examples above to create colorscheme variants as a developer, or
you can use `lush.merge`.

Imaginging you had a base colorscheme, and one which enhanced the brightness of
language statements and another, constants, you could apply `merge` like this:

```lua
-- highlight_constant.lua
local lush = require('lush')
local spec = lush(function()
  return {
    Constant { fg = "red" },
  }
end)
return spec
```

```lua
-- highlight_statement.lua
local lush = require('lush')
local spec = lush(function()
  return {
    Statement { fg = "red" },
  }
end)
return spec
```

You can use merge to apply both of these over your base, like so:

```lua
-- highlight.lua
local lush = require('lush')
local base = require("base")
local constant = require("highlight_constant")
local statement = require("highlight_statement")
local spec = lush.merge({base, constant, statement})
return spec
```

Merge is generally a less powerful `lush.extend().with()` but you may desire to
break your colorscheme up for maintenance or configuration purposes.

## Using Lush Data anywhere

Lush provides an extensible build system called [LushBuild](BUILD.md),
which allows you to export your colorscheme to any format you want.

In addition to LushBuild, every Lush colorscheme is a compiled down to a Lua
table. This lets you import it into other Lua modules, into other colorschemes or
even other lua runtimes.

For example, you could configure your AwesomeWM theme by loading lush and your
colorscheme directly into it's config:

```lua
-- add lush lush and lush colorscheme to lua path
package.path = package.path
                .. ";/home/user/.local/share/nvim/site/plugged/lush.nvim/lua/?.lua"
                .. ";/home/user/.local/share/nvim/site/plugged/lush.nvim/lua/?/?.lua"
                .. ";/home/user/.local/share/nvim/site/plugged/lush-olive-tree/lua/?/?.lua"
-- require lush colorscheme
local olive_tree = require("lush_colorscheme.olive_tree")

-- use lush colorscheme in awesomewm sheme
colorscheme.bg_normal     = olive_tree.SignColumn.bg.hex
colorscheme.bg_error      = olive_tree.Warning.bg.li(30).hex
```

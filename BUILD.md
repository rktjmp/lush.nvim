Lush without Lush
=================

```lua
-- shipwright_build.lua
local colorscheme = require("zenbones")
local lushwright = require("shipwright.transform.lush")
run(colorscheme,
  lushwright.to_vimscript,
  {overwrite, "colors/zenbones.vim"})
```

- [What is Shipwright](#what-is-shipwright)
- [Exporting a colorscheme to Vim Script](#exporting-a-colorscheme-to-vim-script)
- [Exporting a colorscheme to configurable Lua](#exporting-a-colorscheme-to-configurable-lua)
- [Converting a Lush colorscheme into an Alacritty colorscheme](#converting-a-lush-colorscheme-into-an-alacritty-colorscheme)
- [Branch transform](#branch-transform)
- [Transform helpers](#transform-helpers)
- [Transform list](#transform-list)

## What is Shipwright

[Shipwright](https://github.com/rktjmp/shipwright.nvim) is flexible build
system, initially created for Lush but split into its own generic plugin.

To export your lush theme you will have to install Shipwright with your package
manager first:

```lua
use "rktjmp/shipwright.nvim"
```

It is recommended you read the Shipwright readme before continuing as this
guide will build apon the concepts explained there. Shipwright can help you
prepare your colorscheme for use with common terminal emulators and other
tools.

Lush provides some aditional Shipwright transforms for use with parsed lush
specs:

- `to_vimscript`, head, convert parsed spec into vimscript
- `to_lua`, head, convert parsed spec into lua
- `vim_compatible_vimscript`, tail, remove vim-incompatible values from highlight rules

You must `require("shipwright.transform.lush")` in your `shipwright_build.lua`
to access these transforms.

We will discuss the simplest example, where you have a colorscheme with no
variations or configuration options and simply want to let non-lush users use
your colorscheme.

## Exporting a colorscheme to Vim Script

To ship our colorscheme as a vimscript file, we will need to:

- load our colorscheme.
- convert it to vimscript.
- save the output to a file.

We will use the `lush_to_vimscript` and `overwrite` transforms.

Our build file would look something like this:

```lua
-- shipwright_build.lua

local colorscheme = require("my.lush.colorscheme")
local lushwright = require("shipwright.transform.lush")

-- we start by calling run and giving it our colorscheme as the first argument.
-- any other arguments form the pipeline.
run(colorscheme,

  -- now we will convert that colorscheme to a list of vimscript highlight commands
  lushwright.to_vimscript,

  -- we can pass the vimscript through a vim compatible transform if we want.
  -- note: this strips blending
  -- lushwright.vim_compatible_vimscript,

  -- the vimscript commands alone are generally not enough for a colorscheme, we
  -- will need to append a few housekeeping lines first.
  --
  -- note how we are passing arguments to append by wrapping the transform in a table.
  -- {transform 1 2 3} ends up as transform(last_pipe_value, 1, 2, 3)
  --
  -- append() accepts a table of values, or one value, so this call ends up being:
  -- append(last_pipe_value, {"set...",  "let..."})
  {append {"set background=dark", "let g:colors_name=\"my_colorscheme\""}},

  -- now we are ready to write our colors file. note: there is no reason this has
  -- to be written to the relative "colors" dir, you could write the file to an
  -- entirely different vim plugin.
  {overwrite, "colors/my_colorscheme.vim"})

-- and that is the whole build file
```

You can run `:Shipwright <build_file>` which will load and execute the given
build file, or if no buildfile is specified, Shipwright will look for
`shipwright_build.lua` in the current working directory.

Exporting a colorscheme to configurable Lua
-------------------------------------------

The lua transform generates code you can call to load and apply a lush
colorscheme without lush. As Lua colorschemes often have differing styles of
configuration, it will require you to provide a support context around it.

By using the `patchwrite` transform, we can instruct Shipwright to only update
its own code, leaving our support code intact.

First, lets create the build file:

<details>

```lua
-- shipwright_build.lua

local lushwright = require("shipwright.transform.lush")
run(require("colorscheme"),
  -- generate lua code
  lushwright.to_lua,
  -- write the lua code into our destination.
  -- you must specify open and close markers yourself to account
  -- for differing comment styles, patchwrite isn't limited to lua files.
  {patchwrite "colors/colorscheme.lua", "-- PATCH_OPEN", "-- PATCH_CLOSE"})
```

</details>

Before running this build file, we should prepare the destination for
`patchwrite`:

<details>

```lua
-- colors/colorscheme.lua

-- content here will not be touched

-- PATCH_OPEN

-- PATCH_CLOSE

-- content here will not be touched
```

</details>

After running `:Shipwright`, we will have a `lush_apply` function.

By default, `lush_apply` will convert your colorscheme (now compiled as a
table) into vimscript highlight commands and apply them, but you can provide
optional function hooks to `lush_apply` to alter data along the way.

The following hooks are provided:

- `configure_group_fn = function(group) ... end`
  - Accepts a group and may alter that group if needed, to turn italics on or
    off by user config for example.
  - Returns a group shaped table.
- `generate_group_fn = function(group) .. end`
  - Accepts a group and generate *something* that `apply` will understand.
  - By default this is a `highlight ...` vim command but you could return other
    vimscript, raw lua, different tables, etc.
  - The results of this function is collected into a table of "rules", one per
    group.
- `before_apply_fn = function(rules) ... end`
  - A final chance to alter any rules. This could include broad regex's or
    selective deletion, etc.
- `apply_fn = function(rules) ... end`
  - Accepts a table of rules (or whatever was returned by `generate_group ->
    before_apply`) and should do *something* to apply these rules as
    highlights.
  - By default this passes the rules to `vim.cmd` but you could write your own
    handler to use `nvim_set_hl`, etc.

Now that our colorscheme has been exported, we can adjust our `colorscheme.lua`
file to use the generated loader.

<details>

```lua
-- colors/colorscheme.lua

-- PATCH_OPEN
-- Generated by lush builder on Mon Nov  1 22:20:06 2021
--
-- You can configure how this build function operates by passing in optional
-- function handlers via the options table.
--
-- See each default handler below for guidance on writing your own.
--
-- {
--   apply_fn = function(rules) ... end,
--   before_apply_fn = function(rules) ... end,
--   generate_group_fn = function(group) .. end,
--   configure_group_fn = function(group) ... end,
-- }
--
local lush_groups = { ... }
local lush_apply = function(groups, opts)
-- code redacted for brevity
end
-- PATCH_CLOSE

-- imagine we want to provide some optional adjustments to groups
local overrides = {
  Comment = {italic = false}
}

local setup = function(config)
  if config.italic_comments then
    overrides["Comment"]["italic"] = true
  end

  local my_configure_group = function(group)
    if overrides[group.name] then
      if overrides[group.name]["italic"] then
        -- apply configured override
        group.gui = "italic"
      end
    end

    -- return maybe adjusted group
    return group
  end

  -- run lush loader with our custom configure function to
  -- adjust the groups per user config.
  lush_apply(lush_groups, {
    configure_group_fn = my_configure_group
  })
end

return {
  setup = setup
}
```

</details>

Note, you don't have to run this exported lua directly, you could still have
your "core colorscheme file" that takes a config and requires which ever
colorscheme is appropriate.

<details>

```lua

return {
  setup = function(config)
    if config.light then
      require("colorscheme.lush_export.light").apply()
    else
       -- ... etc etc
    end
  end
}
```

</details>

Transform helpers
-----------------

Some helpers are provided to cover common transform tasks. These are a
available under `shipwright.transform.lush.helpers`, see the module for an up
to date list.

```lua
return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
}
```

Transform list
--------------

Every transform accepts and returns a table, this is implied in the
documentation, so "returns commands" means "returns a list of strings, where
each string is a command".

**`to_vimscript`**

- Converts a parsed lush spec into highlight commands.
- Accepts
  - `config`: table passed to `lush.compile`

**`to_lua`**

- Converts a parsed lush spec into lua code.
- Accepts
  - none

**`vim_compatible_vimscript`**

- Removes vim-incompatible attributes from highlight commands
- Accepts
  - none

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
- [Exporting a colorscheme to Lua](#exporting-a-colorscheme-to-configurable-lua)
- [Exporting a colorscheme to Vim Script](#exporting-a-colorscheme-to-vim-script)
- [Converting a Lush colorscheme into an Alacritty colorscheme](#converting-a-lush-colorscheme-into-an-alacritty-colorscheme)
- [Branch transform](#branch-transform)
- [Transform helpers](#transform-helpers)
- [Transform list](#transform-list)

## What is Shipwright

[Shipwright](https://github.com/rktjmp/shipwright.nvim) is flexible build
system. To export your lush theme you will have to install Shipwright
with your package manager first:

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
- `to_lua`, head, convert parsed spec into a table containing `Group =
  {attrs}` strings.
- `vim_compatible_vimscript`, tail, remove vim-incompatible values from highlight rules

You must `require("shipwright.transform.lush")` in your `shipwright_build.lua`
to access these transforms.

We will discuss the simplest example, where you have a colorscheme with no
variations or configuration options and simply want to let non-lush users use
your colorscheme.

Exporting a colorscheme to Lua
-------------------------------------------

The lua transform converts your Lush colorscheme into a table of `group-name =
group-attributes` strings. The generated code is intentionally slim, containing
only the group data. Applying this data is simple but left to the colorscheme
creator.

We will use the `patchwrite` transform so Shipwright will only update
the group data when we run it, leaving our support code intact.

First, lets create the build file:

<details>

```lua
-- shipwright_build.lua

local lushwright = require("shipwright.transform.lush")
run(require("my.lush.colorscheme"),
  -- generate lua code
  lushwright.to_lua,
  -- write the lua code into our destination.
  -- you must specify open and close markers yourself to account
  -- for differing comment styles, patchwrite isn't limited to lua files.
  {patchwrite, "colors/colorscheme.lua", "-- PATCH_OPEN", "-- PATCH_CLOSE"})
```

</details>

Before running this build file, we should prepare the destination for
`patchwrite`:

<details>

```lua
-- colors/colorscheme.lua

local colors = {
-- content here will not be touched
-- PATCH_OPEN
-- group data will be inserted here
-- PATCH_CLOSE
-- content here will not be touched
}

-- colorschemes generally want to do this
vim.cmd("highlight clear")
vim.cmd("set t_Co=256")
vim.cmd("let g:colors_name='my_theme'")

-- apply highlight groups
for group, attrs in pairs(colors) do
  vim.api.nvim_set_hl(0, group, attrs)
end
```

</details>

After running `:Shipwright`, our `colors` variable will be populated
with `group = attributes` pairs. The attribute tables are ready-made
to pass to `nvim_set_hl` though you could modify as desired.

You could also incude different `patchwrite` markers to export multiple
colorschemes (or parts of a colorscheme) to the same file. For example a
base set of colors and a dark & light set, then selectively pass which
groups you want to nvim_set_hl.

You can also include multiple `run()` calls in your shipwright build
file to export a set of colorschemes with one command.

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
  {append, {"set background=dark", "let g:colors_name=\"my_colorscheme\""}},

  -- now we are ready to write our colors file. note: there is no reason this has
  -- to be written to the relative "colors" dir, you could write the file to an
  -- entirely different vim plugin.
  {overwrite, "colors/my_colorscheme.vim"})

-- and that is the whole build file
```

You can run `:Shipwright <build_file>` which will load and execute the given
build file, or if no buildfile is specified, Shipwright will look for
`shipwright_build.lua` in the current working directory.


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

- Converts a parsed lush spec into `group =
  group-attributes` strings for insertion inside a lua
  table form.
- Accepts
  - none

**`vim_compatible_vimscript`**

- Removes vim-incompatible attributes from highlight commands
- Accepts
  - none

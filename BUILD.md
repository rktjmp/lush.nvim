Lush Build
==========

```lua
-- lush_build.lua
local colorscheme = require("zenbones")
run(colorscheme,
  viml,
  {overwrite, "colors/zenbones.vim"})
```

- [What is Lush Build](#what-is-lush-build)
- [Exporting a colorscheme to VimL](#exporting-a-colorscheme-to-viml)
- [Exporting a colorscheme to configurable Lua](#exporting-a-colorscheme-to-configurable-lua)
- [Converting a Lush colorscheme into an Alacritty colorscheme](#converting-a-lush-colorscheme-into-an-alacritty-colorscheme)
- [Pipelines are composable](#pipelines-are-composable)
- [Transform helpers](#transform-helpers)
- [Transform list](#transform-list)

## What is Lush Build

The Lush build system is designed to take a lush spec (i.e. the color and group
data from your colorscheme) and apply any number of transforms to that data.
These transforms can include conversion to a vim colorscheme, terminal emulator
colorscheme, writing to different files, etc.

Each transform is a function that accepts a table and returns a table. The
contents of these tables is not enforced, except for "head" transforms which
must accept a `parsed_lush_spec` (i.e. what is returned by
`require('colorscheme')`).

That is to say, a transform may accept a table of lines and return a table of
functions, or it may accept a table of tables and return a table of lines, etc.

Transforms can take any additional number of arguments after the table.

Lush ships with some default transforms, which are automatically injected into
the build environment:

- `viml`, head, convert parsed spec into viml
- `lua`, head, convert parsed spec into lua
- `prepend`, tail, prepend one or more items to the given table
- `append`, tail, append one or more items to the given table
- `overwrite`, tail, overwrite a file with the given table
- `patchwrite`, tail, selectively overwrite portions of a file with the given table
- `contrib.alacritty`, tail, convert given table into an alacritty colorscheme
- `contrib.kitty`, tail, convert given table into a kitty colorscheme
- `contrib.wezterm`, tail, convert given table into a wezterm colorscheme

In addition to these transforms, the following are also injected into the build
environment:

- `lush`, the Lush module
- `run`, a function to start a pipeline

You can provide any of your own transforms just by writing a function, either
in the build file or in another module.

We will discuss the simplest example, where you have a colorscheme with no
variations or configuration options and simply want to let non-lush users use
your colorscheme.

## Exporting a colorscheme to VimL

To ship our colorscheme as a viml file, we will need to:

- load our colorscheme.
- convert it to viml.
- save the output to a file.

We will use the `viml` and `overwrite` transforms.

Our build file would look something like this:

```lua
-- lush_build.lua

local colorscheme = require("my.lush.colorscheme")

-- we start by calling run and giving it our colorscheme as the first argument.
-- any other arguments form the pipeline.
run(colorscheme,

  -- now we will convert that colorscheme to a list of viml highlight commands
  viml,

  -- the viml commands alone are generally not enough for a colorscheme, we
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

You can run `:LushBuild <build_file>` which will load and execute the given
build file, or if no buildfile is specified, Lush will look for
`lush_build.lua` in the current working directory.

It's important to remember:

- The build file is "just lua", you can use any normal lua inside it, including
  loops, other modules, etc. You can even define, extend or merge Lush specs
  inside the build file.
- Transformers are "just functions", so it's very simple to write your own
  extensions to the provided transforms.

As a further example, we will write our own transform next.

## Converting a Lush colorscheme into an Alacritty colorscheme

As an example, we will convert a colorscheme into a (truncated) Alacritty
colorscheme.

> Note: Lush provides an alacritty transform (`contrib.alacritty`), but it
> makes a good example.

To do this we will need to:

- collect a subset of groups to export.
- convert `#000000` hex values to `0x000000`.
- downcase our hex values.
- generate a yaml file for use with Alacritty.

<details>

```lua
-- As an example, we will imagine we are developing a lush transform
-- for release into the community.
--
-- We will say this transform expects to get a table shaped as:
--
-- {
--   primary = {
--     bg = color
--     fg = color
--   }
-- }
--
-- along with a name.

local function hash_to_0x(color)
  return string.lower(string.gsub(color, "^#", "0x"))
end

local function alacritty(colors, name)
  return {
    "# Colors: " .. name,
    "colors:",
    "  primary:"
    "    background: '" .. hash_to_0x(colors.primary.bg) .. "'",
    "    foreground: '" .. hash_to_0x(colors.primary.fg) .. "'",
  }
end

return alacritty
```

```lua
-- lush_build.lua

local colorscheme = require("my_colorscheme")
local alacritty = require("lush_community.transform.alacritty")

run(colorscheme,
  -- we must process our colorscheme to conform to the alacritty transforms format.
  -- we can do this with an inline transform.
  function (groups)
    return {
      primary = {
        bg = groups.Normal.bg,
        fg = groups.Normal.fg
      }
    }
  end,

  -- now we can pass to alacritty, note that the transform accepts a name,
  -- so we use a table with the transform and it's argument.
  {alacritty, "my_colorscheme"},

  -- and now we can write, either to share or to our local config
  {overwrite, "~/.config/alacritty/colorscheme.yaml"}

  -- note, as overwrite is a transform, it *must* return a table, and infact
  -- overwrite returns the same lines it was given. we can pass these lines
  -- another transform.
  {overwrite, "extra/terms/alacritty.yaml"})
```

</details>

Exporting a colorscheme to configurable Lua
-------------------------------------------

The lua transform generates code you can call to load and apply a lush
colorscheme without lush. As Lua colorschemes often have differing styles of
configuration, it will require you to provide a support context around it.

By using the `patchwrite` transform, we can instruct the lush build system to
only update its own code, leaving our support code intact.

First, lets create the build file:

<details>

```lua
-- lush_build.lua

run(require("colorscheme"),
  -- generate lua code
  lua,
  -- write the lua code into our destination.
  -- you must specify open and close markers yourself to account
  -- for differing comment styles, patchwrite isn't limited to lua files.
  {patchwrite "colors/colorscheme.lua", "-- PATCH_OPEN", "-- PATCH_CLOSE"})
```

</details>

Before running this build file, we should prepare the destination for `patchwrite`:

<details>

```lua
-- colors/colorscheme.lua

-- content here will not be touched

-- PATCH_OPEN

-- PATCH_CLOSE

-- content here will not be touched
```

</details>

After running `:LushBuild`, we will have a `lush_apply` function.

By default, `lush_apply` will convert your colorscheme (now compiled as a
table) into viml highlight commands and apply them, but you can provide
optional function hooks to `lush_apply` to alter data along the way.

The following hooks are provided:

- `configure_group_fn = function(group) ... end`
  - Accepts a group and may alter that group if needed, to turn italics on or
    off by user config for example.
  - Returns a group shaped table.
- `generate_group_fn = function(group) .. end`
  - Accepts a group and generate *something* that `apply` will understand.
  - By default this is a `highlight ...` vim command but you could return other
    viml, raw lua, different tables, etc.
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

Pipelines are composable
------------------------

Since run itself is a transform, you can pipe any table value into it, along
with a list of transforms to run in that context.

```lua
run(zenbones,
  viml,
  {run, {
    {prepend, [["see http://... for more details]]},
    {patchwrite, "../dist/...", [[" M_OPEN]], [[" M_CLOSE]]}}}
  {run, {
    {patchwrite, "colors/", [[" M_OPEN]], [[" M_CLOSE]]}}})

-- or
run(zenbones,
  extract_term_colors, -- generic map of colors to use in terminals
  {run, {
    term_colors_to_kitty_map, -- translate generic map to kitty shaped map
    contrib.kitty,
    {overwrite, "extra/kitty.conf"}}},
  {run, {
    term_colors_to_alacritty_map, -- translate generic map to alacritty shaped map
    contrib.alacritty,
    {overwrite, "extra/alacritty.yaml"}}})
```

Transform helpers
-----------------

A number of helpers are provided to cover common transform tasks. These are a
available under `lush.transform.helpers`, see the module for an up to date
list.

```lua
return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
  -- split string into table by new lines
  split_newlines = split_newlines,
  -- apply "this is my $template", {template = "replacement"} templating
  apply_template = apply_template,
  -- {r = 255, g = 255, b = 255} -> "0xffffff"
  rgb_to_hex = rgb_convert.rgb_to_hex,
  -- "0xffffff" -> {r = 255, g = 255, b = 255}
  hex_to_rgb = rgb_convert.hex_to_rgb
}
```

Transform list
--------------

Every transform accepts and returns a table, this is implied in the
documentation, so "returns commands" means "returns a list of strings, where
each string is a command".

**`viml`**

- Converts a parsed lush spec into highlight commands.
- Accepts
  - `config`: table passed to `lush.compile`

**`lua`**

- Converts a parsed lush spec into lua code.
- Accepts
  - none

**`prepend`**

- Prepends given arguments to given table.
- Accepts
  - a table of items to prepend, or a single item

**`append`**

- Appends given arguments to given table.
- Accepts
  - a table of items to append, or a single item

**`overwrite`**

- Writes the given table (assumes strings) to path, overwrites any existing
  content.
- Accepts
  - a path to write to

**`patchwrite`**

- Writes the given table (assumes strings) to path, writes content only between
  given start and stop markers.
- Accepts
  - a path to write to
  - a string to match against, indicating where writing should start
  - a string to match against, indicating where writing should stop

**`contrib.alacritty`**

- Converts given table to an alacritty colorscheme
- Accepts
  - a specifically shaped map, see transform for exact format.

**`contrib.kitty`**

- Converts given table to an kitty colorscheme
- Accepts
  - a specifically shaped map, see transform for exact format.

**`contrib.wezterm`**

- Converts given table to an wezterm colorscheme
- Accepts
  - a specifically shaped map, see transform for exact format.

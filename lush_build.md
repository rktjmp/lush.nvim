Lush Build
==========

```lua
-- lush_build.lua
local theme = require("zenbones")
run(theme,
  viml,
  {overwrite, "colors/zenbones.vim"})
```

- [What is Lush Build](#what_is_lush_build)
- [Exporting a colorscheme to VimL](#exporting_a_colorscheme_to_viml)
- [Exporting a colorscheme to configurable Lua](#exporting_a_colorscheme_to_configurable_lua)
- [Converting a Lush colorscheme into an Alacritty theme](#converting_a_lush_colorscheme_into_an_alacritty_theme)
- [Pipelines are composable](#pipelines_are_composable)
- [Transform helpers](#transform_helpers)

## What is Lush Build

The Lush build system is designed to take a lush spec (i.e. the color and group
data from your theme) and apply any number of transforms to that data. These
transforms can include conversion to a vim theme, terminal emulator theme,
writing to different files, etc.

Each transform is a function that accepts a table and returns a table. The
contents of these tables is not enforced, except for "head" transforms which
must accept a `parsed_lush_spec` (i.e. what is returned by `require('theme')`).

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
- `contrib.alacritty`, tail, convert given table into an alacritty theme
- `contrib.kitty`, tail, convert given table into a kitty theme
- `contrib.wezterm`, tail, convert given table into a wezterm theme

In addition to these transforms, the following are also injected into the build environment:

- `lush`, the Lush module
- `run`, a function to start a pipeline

You can provide any of your own transforms just by writing a function, either
in the build file or in another module.

We will discuss the simplest example, where you have a theme with no variations
or configuration options and simply want to let non-lush users use your theme.

## Exporting a colorscheme to VimL

To ship our theme as a viml file, we will need to:

- load our theme.
- convert it to viml.
- save the output to a file.

We will use the `viml` and `overwrite` transforms.

Our build file would look something like this:

```lua
-- lush_build.lua

local theme = require("my.lush.theme")

-- we start by calling run and giving it our theme as the first argument.
-- any other arguments form the pipeline.
run(theme,

  -- now we will convert that theme to a list of viml highlight commands
  viml,

  -- the viml commands alone are generally not enough for a colorscheme, we
  -- will need to append a few housekeeping lines first.
  --
  -- note how we are passing arguments to append by wrapping the transfor in a table.
  -- {transform 1 2 3} will result in transform(last_pipe_value, 1, 2, 3)
  --
  -- append() accepts a table of values, or one value, so this call ends up being:
  -- append(last_pipe_value, {"set...",  "let..."})
  {append {"set background=dark", "let g:colors_name=\"my_theme\""}},

  -- now we are ready to write our colors file. note: there is no reason this has
  -- to be written to the relative "colors" dir, you could write the file to an
  -- entirely different vim plugin.
  {overwrite, "colors/my_theme.vim"})

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

## Converting a Lush theme into an Alacritty theme

As an example, we will convert a theme into a (truncated) Alacritty theme.

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
    "# Colors: " .. name .. " theme",
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

local theme = require("my_theme")
local alacritty = require("lush_community.transform.alacritty")

run(theme,
  -- we must adjust our theme to conform to the alacritty transforms format.
  -- we can do this with an inline transform.
  function (groups)
    return {
      primary = {
        bg = groups.Normal.bg,
        fg = groups.Normal.fg
      }
    }
  end,

  -- now we can pass to alacritty, note that it needs a name
  {alacritty, "my_theme"},

  -- and now we can write, either to share or to our local config
  {overwrite, "~/.config/alacritty/theme.yaml"}

  -- note, as overwrite is a transform, it *must* return a table, and infact
  -- overwrite returns the same lines it was given. we can pass these lines
  -- another transform.
  {overwrite, "extra/terms/alacritty.yaml"})
```

</details>

Exporting a colorscheme to configurable Lua
-------------------------------------------

The lua transform generates code you can call to load and apply a lush theme
without lush. As Lua themes often have differing styles of configuration, it
will require you to provide a support context around it.

By using the `patchwrite` transform, we can instruct the lush build system to
only update its own code, leaving our support code intact.


First, lets create the build file:

<details>

```lua
-- lush_build.lua

run(require("theme"),
  -- generate lua code
  lua,
  -- write the lua code into our destination.
  -- you must specify open and close markers yourself to account
  -- for differing comment styles, patchwrite isn't limited to lua files.
  {patchwrite "colors/theme.lua", "-- PATCH_OPEN", "-- PATCH_CLOSE"})
```

</details>

Before running this build file, we should prepare the destination for `patchwrite`:

<details>

```lua
-- colors/theme.lua

-- content here will not be touched

-- PATCH_OPEN

-- PATCH_CLOSE

-- content here will not be touched
```

</details>

After running `:LushBuild`, we will have a `lush_apply` function.

By default, `lush_apply` will convert your theme (now compiled as a table) into
viml highlight commands and apply them, but you can provide optional function
hooks to `lush_apply` to alter data along the way.

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

Now that our theme has been exported, we can adjust our `theme.lua` file to use
the generated loader.

<details>

```lua
-- colors/theme.lua

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
...
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
your "core theme file" that takes a config and requires which ever theme is
appropriate.

<details>

```lua

return {
  setup = function(config)
    if config.light then
      require("theme.lush_export.light").apply()
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
available under `lush.transform.helpers`, see the module for an up to date list.

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

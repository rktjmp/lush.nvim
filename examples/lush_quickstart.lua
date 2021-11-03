--
--        ,gggg,
--       d8" "8I                         ,dPYb,
--       88  ,dP                         IP'`Yb
--    8888888P"                          I8  8I
--       88                              I8  8'
--       88        gg      gg    ,g,     I8 dPgg,
--  ,aa,_88        I8      8I   ,8'8,    I8dP" "8I
-- dP" "88P        I8,    ,8I  ,8'  Yb   I8P    I8
-- Yb,_,d88b,,_   ,d8b,  ,d8b,,8'_   8) ,d8     I8,
--  "Y8P"  "Y888888P'"Y88P"`Y8P' "YY8P8P88P     `Y8
--

-- This is the lush quickstart tutorial, it provides a basic overview
-- of the lush experience and API.
--
-- First, enable lush.ify on this file, run:
--
--  `:Lushify`
--
--  or
--
--  `:lua require('lush').ify()`
--
-- (try putting your cursor inside the ` and typing yi`:@"<CR>)
--
-- Calls to hsl()/hsluv() are now highlighted with the correct background colour
-- Highlight names groups will have the highlight style applied to them.

local lush = require('lush')
local hsl = lush.hsl
-- You may also use the HSLuv colorspace, see http://www.hsluv.org/ and h: lush-hsluv-colors.
-- Replace calls to hsl() with hsluv()
-- local hsluv = lush.hsluv

-- HSL stands for Hue        (0 - 360)
--                Saturation (0 - 100)
--                Lightness  (0 - 100)
--
-- By working with HSL, it's easy to define relationships between colours.

local sea_foam  = hsl(208, 80, 80)  -- Vim has a mapping, <n>C-a and <n>C-x to
local sea_crest = hsl(208, 90, 30)  -- increment or decrement integers, or
local sea_deep  = hsl(208, 90, 10)  -- you can just type them normally.
local sea_gull  = hsl("#c6c6c6")    -- Or use hex form, preceeded with a #.

-- Note: Some CursorLine highlighting will obscure any other highlighing on the
--       current line until you move your cursor.
--
--       You can disable the cursor line temporarily with:
--
--       `setlocal nocursorline`

-- Lush.hsl provides a number of convenience functions for:
--
--   Relative adjustment: rotate(), saturate(), desaturate(), lighten(), darken()
--                        aliased to ro(), sa() de(), li(), da(), mix(), readable()
--   Overide:             hue(), saturation(), lightness()
--   Access:              .h, .s, .l
--   Coercion:            tostring(), "Concatenation: " .. color

-- To define our colour scheme, we will write what is called a lush-spec.
-- We will use lush.hsl as an aid.

-- A lush-spec function which returns a table, which defines our
-- highlight groups. It's usage is much simpler than it reads.
-- We'll define our lush-spec below.

-- Call lush with our lush-spec.
---@diagnostic disable: undefined-global
local theme = lush(function()
  return {
    -- It's recommended to disable wrapping with `setlocal nowrap`.  You may
    -- also receive (mostly ignorable) linter/lsp warnings, because our lua is
    -- a bit more dynamic than they expect.  You may also wish to disable those
    -- while editing your theme if they produce a lot of visual noise.

    -- lush-spec statements are in the form:
    --
    --   <HighlightGroupName> { bg = <hsl>|<string>,
    --                          fg = <hsl>|<string>,
    --                          sp = <hsl>|<string>,
    --                          gui = <string> },
    --
    -- Any vim highlight group name is valid, and any unrecognized key is
    -- omitted.
    --
    -- Lets define our "Normal" highlight group, using our sea colours.

    -- Set a highlight group from the hsl variables we defined at the start
    -- Uncomment "Normal"
    -- Normal { bg = sea_deep, fg = sea_foam }, -- normal text

    -- You should be on the water now, Lush.ify has automatically recognized
    -- our Highlight definition and applied it in real time.

    -- Lush is most useful when you use previously defined groups aid in
    -- picking colours for future groups.
    --
    -- For example, lets set our cursorline (if disabled: `setlocal cursorline`)
    -- to be slightly lighter than our normal background.

    -- Set a highlight group from another highlight group
    -- CursorLine { bg = Normal.bg.lighten(5) }, -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.

    -- Or maybe lets style our visual selection to match Cusorlines background,
    -- and render text in Normal's foreground complement.
    -- Visual { bg = CursorLine.bg, fg = Normal.fg.rotate(180) },

    -- We can also link a group to another group. These will inherit all of the
    -- linked group options (See h: hi-link). (`setlocal cursorcolumn`)
    -- CursorColumn { CursorLine },

    -- We can make white space characters slighly visible
    -- Whitespace { fg = Normal.bg.desaturate(25).lighten(25) },

    -- We can inherit properties if we want to tweak a group slightly
    -- Note: This looks similar to a link, but the defined group will have its
    -- own properties, cloned from the parent.
    -- Lets make Comments look like Whitespace, but with italics
    -- Comment { Whitespace, gui="italic" },

    -- Here's how we might set our line numbers to be relational to Normal,
    -- note that we're also using some function aliases, see the readme for more
    -- information.
    -- (`setlocal number`)
    -- LineNr       { bg = Normal.bg.da(10), fg = Normal.bg.li(5) }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    -- CursorLineNr { bg = CursorLine.bg, fg = Normal.fg.ro(180) }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.

    -- You can also use highlight groups to define "base" colors, if you dont
    -- want to use regular Lua variables. They will behave in the same way.
    -- Note that these groups *will* be defined as a vim-highlight-group, so
    -- try not to pick names that might end up being used by something else.
    --
    -- CamelCase is by tradition but you don't have to use it.
    -- search_base  { bg = hsl(52, 52, 52), fg = hsl(52, 10, 10) },
    -- Search       { search_base },
    -- IncSearch    { bg = search_base.bg.ro(-20), fg = search_base.fg.da(90) },

    -- We can also mix colours together
    -- Type         { fg = Normal.fg.mix(LineNr.fg, 30) }

    -- And that's the basics of using Lush!
    --
    -- For more information, see the README and :h lush or run :LushRunTutorial
  }
end)

-- return our parsed theme for extension or use else where.
return theme

-- vi:nowrap:number

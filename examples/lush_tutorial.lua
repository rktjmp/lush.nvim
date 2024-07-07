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

-- This is the lush tutorial, it provides a basic demo of the lush
-- experience and API and should only take a few minutes.
--
-- For more information, see:
--
-- * :h lush
-- * CREATE.md
-- * EXTEND.md
-- * README.md
--
-- Look out! We're currently working in a temporary buffer. If you want to
-- keep anything you do here, make sure you use `:saveas <your filename>`!
-- Just using `:w` wont work! It's probably best to quickly run through this
-- file, then discard it and see CREATE.md for more instructions about setting
-- up your own theme.



-- ###
-- ### Lushify
-- ###
--
-- First, we'll "lushify" this file, which will enable realtime feedback for
-- your changes. We do this by running the command:
--
-- `:Lushify`
--
--  Also make sure to enable termguicolors with `:set termguicolors`.
--
-- (If it worked, your colorscheme should have changed pretty dramatically!)



-- ###
-- ### Preparations
-- ###
--
-- To use lush, we must require lush:

local lush = require('lush')

-- Lush uses the HSL colorspace to define colors because it allows for
-- more natural operations on colors and the relationships between colors is
-- simpler to understand.
--
-- Instead of RGB where you specify red, green and blue components, HSL uses:
--
-- Hue        (0 - 360) (each value is a angle around the color wheel)
-- Saturation (0 - 100) (0 is gray, 100 is colored)
-- Lightness  (0 - 100) (0 is black, 100 is white)
--
-- Lush also supports HSLuv (http://www.hsluv.org/, `h: lush-hsluv-colors`) as well
-- as raw '#rrggbb' or 'colorname' strings colors, though string colors dont
-- support operations.

local hsl = lush.hsl -- We'll use hsl a lot so its nice to bind it separately
-- local hsluv = lush.hsluv -- or for hsluv



-- ###
-- ### Our first colors
-- ###
--
-- Let's define some colors (the hsl() calls should already be highlighted for you):
--
-- Note: Some CursorLine highlighting will obscure any other highlighing on the
--       current line until you move your cursor away. You can disable the cursor
--       line temporarily with: `setlocal nocursorline` if it's causing issues.

local sea_foam  = hsl(208, 100, 80) -- Vim has a mapping, <n>C-a and <n>C-x to
local sea_crest = hsl(208, 90, 30)  -- increment or decrement integers, or
local sea_deep  = hsl(208, 90, 10)  -- you can just type them normally.

-- You can see we have 3 blues, all with the same hue and adjusted levels
-- of saturation and brightness. They naturally sit well together.
--
-- Try editing these values to see the colors update in real time.

-- RGB colors can be given as "#rrggbb". hsl() will convert them to
-- the corresponding hue, saturation, and lightness values. 
local sea_gull  = hsl("#c6c6c6")
-- Note: Converting between colorspaces can introduce minor color differences
--       due to floating point maths. You may prefer to manually adjust your
--       colors "by eye" afterwards.



-- ###
-- ### HSL operations
-- ###
--
-- Lush.hsl (and hsluv) provides a number of convenience functions for:
--
--   Relative adjustment (rotate(), saturate(), desaturate(), lighten(), darken())
--   Absolute adjustment (prefix above with abs_)
--   Combination         (mix())
--   Overrides           (hue(), saturation(), lightness())
--   Access              (.h, .s, .l)
--   Coercion            (tostring(), "Concatination: " .. color)
--   Helpers             (readable())
--
--   Adjustment functions have shortcut aliases, ro, sa, de, li, da
--                                               abs_sa, abs_de, abs_li, abs_da
--
-- Because HSL colors are represented by degrees around a colorwheel, we can find
-- harmonious colors from our original set by rotating the hue:
local sea_foam_triadic = sea_foam.rotate(120)
-- And we can also chain these operations:
local sea_foam_complement = sea_foam.rotate(180).darken(10).saturate(10)
--
-- Thats all you need to know about HSL and we can define our theme!



-- ###
-- ### Lush specifications
-- ###
--
-- A lush theme is built from a lush-spec, which is a function, that returns a
-- table, that we pass to lush().
--
-- This sounds a lot more complicated than it is in practice. See below where we do
-- it all in one go, we call lush(), and pass it a function(), that returns a { table }.
--
---@diagnostic disable: undefined-global
local theme = lush(function()
  return {
    -- (You might want to disable line wrapping here via `setlocal nowrap`.)
    --
    -- Each element in the table should match this format:
    --
    --   <HighlightGroupName> { bg = <hsl>|<string>,
    --                          fg = <hsl>|<string>,
    --                          sp = <hsl>|<string>,
    --                          gui = <string>,
    --                          ... },
    --
    -- Any vim highlight group name is valid, and any unrecognized key is
    -- removed.

    -- Every theme needs a "Normal" group, so let's define that first. You can
    -- see we already have a definition prepared, so just remove uncomment the
    -- line directly after this one.
    -- Normal { bg = sea_deep, fg = sea_foam }, -- Goodbye gray, hello blue!

    -- You should immediately see your background and text color change to the
    -- colors we setup before. That's all there is to writing basic highlight groups
    -- with Lush!
    --
    -- But we can do more. Lush can use previous groups to define new ones, as
    -- well as access properties of those groups.
    --
    -- For example, let's set our CursorLine to be slightly lighter than our
    -- normal background. (If disabled: `setlocal cursorline`).
    -- We can do this by setting the background property (bg) to the Normal
    -- groups background, lightened by a few points.
    -- CursorLine { bg = Normal.bg.lighten(10) }, -- lighten() can also be called via li()
    -- Also note that (after you move your cursor away from the line) the text
    -- "CursorLine" is highlighted to match the definition, so you can always
    -- see how parts of your theme will look.

    -- We can swap colors around too, let's make our visual selection ("v mode")
    -- the inverse of Normal.
    -- Visual { fg = Normal.bg, bg = Normal.fg }, -- Try pressing v and selecting some text

    -- We can adjust our comments to look like desaturate normal text
    -- Comment { fg = Normal.bg.de(25).li(25).ro(-10) },

    -- Besides directly using group properties, we can define two relationships
    -- between groups, "link" and "inherit".
    --
    -- Link is natively supported by Neovim (see `:h hl-link`), both groups
    -- will appear the same, and changes to the "root" will effect the other.
    --
    -- Inherit groups behave similarly to link, but the parent group properties
    -- are copied to the child, and then any changed properties override the
    -- parent.

    -- For example, let's "link" CursorColumn to CursorLine.
    -- (If disabled: `setlocal cursorcolumn`)
    -- CursorColumn { CursorLine }, -- CursorColumn is linked to CursorLine

    -- Or we can make LineNr inherit from Comment, but we'll adjust the gui
    -- property (`setlocal number`)

    -- LineNr { Comment, gui = "italic" },
    -- Try writing your own above and below line number groups, and
    -- experiment with the different operations listed at the start of this
    -- file.
    -- LineNrBelow { LineNr },
    -- LineNrAbove { LineNr },
    -- CursorLineNr { LineNr, fg = CursorLine.bg.mix(Normal.fg, 50) },

    -- Finally you can also use highlight groups to define "base" colors, if
    -- you dont want to use regular Lua variables. They will behave in the same
    -- way. Note that these groups *will* be defined as a vim-highlight-group,
    -- so try not to pick names that might end up being used by something else.
    --
    -- CamelCase is by tradition but you don't have to use it.
    -- search_base  { bg = hsl(52, 52, 52), fg = hsl(52, 10, 10) },
    -- Search       { search_base },
    -- IncSearch    { bg = search_base.bg.ro(-20), fg = search_base.fg.da(90) },
  }
end)

-- Return our parsed theme for use and that's the basics of using Lush!
-- The parsed theme can be used as a neovim theme, or extended further via Lush,
-- or used elsewhere such as in other lua runtimes.
return theme



-- ###
-- ### Other tools
-- ###
--
-- By default, lush() actually returns your theme as a table. You can
-- interact with it in much the same way as you can inside a lush-spec.
--
-- This looks something like:
--
--   local theme = lush(function()
--     -- define a theme
--     return {
--       Normal { fg = hsl(0, 100, 50) },
--       CursorLine { Normal },
--     }
--   end)
--
--   -- behaves the same as above:
--   theme.Normal.fg()                     -- returns table {h = h, s = s, l = l}
--   tostring(theme.Normal.fg)             -- returns "#hexstring"
--   tostring(theme.Normal.fg.lighten(10)) -- you can still modify colors, etc
--
-- This means you can `require('my_lush_file')` in any lua code to access your
-- themes's color information (including outside of neovim).
--
-- Note:
--
-- "Linked" groups do not expose their colors, you can find the key
-- of their linked group via the 'link' key (may require chaining)
--
--   theme.CursorLine.fg() -- This is bad!
--   theme.CursorLine.link -- = "Normal"
--
-- Also Note:
--
-- Most plugins expose their own Highlight groups, which *should be the primary
-- method for setting theme colors*, there are however some plugins that
-- require adjustments to a global or configuration variable.
--
-- To set a global variable, use neovims lua bridge,
--
--   vim.g.my_plugin.color_for_widget = theme.Normal.fg.hex
--
--
-- For more information, see the README.md, CREATE.md, EXTEND.md and `:h lush`.

-- vi:nowrap:number

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
-- This is an starter lush-spec colour scheme and tutorial.
-- Copy it to your own <theme>/lua/<theme_name>.lua and edit,
-- or open it and follow the instructions to explore Lush.
--
-- Note: Because this is lua file, vim will append your file to the runtime,
--       which means you can require(...) it in other lua code (this is useful),
--       but you should also take care not to conflict with other libraries.
--
--       (This is a lua quirk, as it has somewhat poor support for namespacing.)
--
--       Basically, name your file "super_theme/lua/super_theme_dark.lua",
--       not "super_theme/lua/dark.lua".
--
--       With that caveat out of the way...
--

-- First, enable lush.ify on this file, run:
--
--  `:lua require('lush').ify()`
--
-- (try putting your cursor inside the ` and typing yi`:@"<CR>)
--
-- Calls to hsl() are now highlighted with the correct background colour
-- Highlight names groups will have the highlight style applied to them.

-- Lets get started, first we have to require lush, and optionally bind
-- hsl to a more usable name. HSL can also be imported into other modules.

local lush = require('lush')
local hsl = lush.hsl

-- HSL stands for Hue        (0 - 360)
--                Saturation (0 - 100)
--                Lightness  (0 - 100)
--
-- By working with HSL, it's easy to define relationships between colours.
--
-- For example, rotating a hue between 30 and 60 degrees will find harmonious
-- colours, or 180 degrees will find it's complementary colour. Colour theory
-- is beyond the scope of this document, but with the examples below it
-- should start to make some sense.
--
-- Lets define some colors (these should already be highlighted for you):

local sea_foam  = hsl(208, 80, 80)  -- Try presing C-a and C-x
local sea_crest = hsl(208, 90, 30)  -- to increment or decrement
local sea_deep  = hsl(208, 90, 10)  -- the integers used here.

-- You can see we have 3 blues, all with the same hue and adjusted levels
-- of saturation and brightness. They naturally sit well together.
--
-- Try editing these values to see the colours update in real time.
--
-- Remember hue (0-360), saturation (0-100), lightness (0-100)
-- (HSL will fix any invalid values internally.)
--
-- Note: Some CursorLine highlighting will obscure any other
--       highlighing on the current line until you move your cursor.
--
--       You can disable the CursorLine group temporarily with:
--
--       `:hi! CursorLine NONE`

-- Many online palette helpers provide hex values by default, so you can
-- also import those into hsl.

local sea_gull = hsl("#c6c6c6") -- as as string, preceeded with a #

-- Lush.hsl provides a number of conveniece functions for:
--
--   Relative adjustment (roatate(), saturate(), desaturate(), lighten(), darken())
--   Overrides           (hue(), saturation(), lightness())
--   Access              (.h, .s, .l)
--   Coercion            (tostring(), "Concatination: " .. color)
--   TODO: relative vs absolute adjustment, short codes
--

-- Lets find some harmonious colours from our original set.
-- (Unfortunately, deep inspection of lushify modifiers is currently WIP.)

-- rotate 120 deg arond the colour wheel
local sea_foam_triadic = sea_foam.rotate(120)

-- rotate 180 degrees, darken and saturate the colour.
local sea_foam_compliment = sea_foam.rotate(180).darken(10).saturate(10)

-- Now that you know the basics of using hsl(), we can define our colour
-- scheme. Do do this, we will write what is called a lush-spec.

-- We must pass a function to Lush, which returns a table containing
-- our spec. This may seem a little confusing at first, it's a lua quirk.
--
-- When called in this manner, Lush will process our lush-spec,
-- clear any existing syntax and highlight groups, then apply our scheme.
--
-- If you want more control over the application or to explort for use
-- without Lush, see TODO lush.create() lush.apply() stringify()

-- Call lush with our lush-spec.
-- ignore the "theme" variable for now
local theme = lush(function()
  return {
    -- It's recommended to disable wrapping with `setlocal nowrap`.
    -- You may also receive (mostly ignorable) linter/lsp warnings,
    -- because our lua is a bit more dynamic than they expect.
    -- You may also wish to disable those while editing your theme
    -- they produce a lot of visual noise.

    -- lush-spec statements are in the form:
    --
    --   <HighlightGroupName> { bg = <hsl>, fg = <hsl>, gui/sp= <string> },
    --
    -- Any vim highlight group name is valid, and any key can be omitted.
    --
    -- Lets define our "Normal" highlight group, using our sea colours.

    -- Set a highlight group from hsl variables
    -- Remove comment infront of "Normal"
    -- Normal       { bg = sea_deep, fg = sea_foam }, -- normal text

    -- You should be on the water now, Lush.ify has automatically
    -- recognized our Highlight definition and applied it in real time.

    -- Lush is most useful when you use previously defined groups aid in
    -- picking colours for future groups.
    --
    -- For example, lets set our cursorline (if enabled: `set cursorline`)
    -- to be slightly lighter than our normal background.
    --
    -- Set a highlight group from another highlight group
    -- CursorLine   { bg = Normal.bg.lighten(5) }, -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.

    -- Or maybe lets style our visual selection to match Cusorlines background,
    -- and render text in Normal's foreground complement.
    -- Visual { bg = CursorLine.bg, fg = Normal.fg.rotate(180) },

    -- We can also link a group to another group. These will inherit all
    -- of the linked group options (See h: hi-link).
    -- (`set cursorcolumn`)
    -- CursorColumn { CursorLine }, -- Screen-column at the cursor, when 'cursorcolumn' is set.

    -- Here's how we can set comments to be slightly less visible and italic.
    -- (italics are terminal support dependent)
    -- Comment      { fg = Normal.bg.desaturate(25).lighten(25), gui="italic" }, -- (preferred) any comment

    -- Here's how we might set our line numbers to be relational to Normal,
    -- with some TODO NOTE short hands
    -- (`set number`)
    -- LineNr       { bg = Normal.bg.dar(30), fg = Normal.fg.dar(70) }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    -- CursorLineNr { bg = CursorLine.bg, fg = Normal.fg.ro(180) }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.

    -- You can also use highlight groups to define "base" colors, if you dont
    -- want to use regular lua variables. They will behave in the same way.
    -- Note that these groups *will* be defined as a vim-highlight-group, so
    -- try not to pick names that might end up being used by something.
    --
    -- CamelCase is by tradition but you don't have to use it.
    -- search_base  { bg = hsl(52, 52, 52), fg = hsl(52, 10, 10) },
    -- Search       { search_base },
    -- IncSearch    { bg = search_base.bg.rotate(-20), fg = search_base.fg.darken(90) },

    -- And that's the basics of using Lush!
    --
    -- If you want to know more about exporting themes for use without lush
    -- (for distribution) or integration with other plugins (such as
    -- lightline), see the bottom of this file `/export-external`

    -- The following are all the Neovim default highlight groups from
    -- docs as of 0.5.0-812, to aid your theme creation. Your themes should
    -- probably style all of these at a bare minimum.
    --
    -- Referenced/linked groups must come before being referenced/lined,
    -- (i.e. above we create Normal before trying to set CursorLine)
    -- so the order shown ((mostly) alphabetical) is likely
    -- not the order you will end up with.
    --
    -- You can uncomment these and leave them empty to disable any
    -- styling for that group (meaning they mostly get styled as Normal)
    -- or leave them commented to apply vims default colouring or linking.

    -- NormalFloat  { }, -- Normal text in floating windows.
    -- ColorColumn  { }, -- used for the columns set with 'colorcolumn'
    -- Conceal      { }, -- placeholder characters substituted for concealed text (see 'conceallevel')
    -- Cursor       { }, -- character under the cursor
    -- lCursor      { }, -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    -- CursorIM     { }, -- like Cursor, but used when in IME mode |CursorIM|
    -- Directory    { }, -- directory names (and other special names in listings)
    -- DiffAdd      { }, -- diff mode: Added line |diff.txt|
    -- DiffChange   { }, -- diff mode: Changed line |diff.txt|
    -- DiffDelete   { }, -- diff mode: Deleted line |diff.txt|
    -- DiffText     { }, -- diff mode: Changed text within a changed line |diff.txt|
    -- EndOfBuffer  { }, -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    -- TermCursor   { }, -- cursor in a focused terminal
    -- TermCursorNC { }, -- cursor in an unfocused terminal
    -- ErrorMsg     { }, -- error messages on the command line
    -- VertSplit    { }, -- the column separating vertically split windows
    -- Folded       { }, -- line used for closed folds
    -- FoldColumn   { }, -- 'foldcolumn'
    -- SignColumn   { }, -- column where |signs| are displayed
    -- Substitute   { }, -- |:substitute| replacement text highlighting
    -- MatchParen   { }, -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    -- ModeMsg      { }, -- 'showmode' message (e.g., "-- INSERT -- ")
    -- MsgArea      { }, -- Area for messages and cmdline
    -- MsgSeparator { }, -- Separator for scrolled messages, `msgsep` flag of 'display'
    -- MoreMsg      { }, -- |more-prompt|
    -- NonText      { }, -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    -- NormalNC     { }, -- normal text in non-current windows
    -- Pmenu        { }, -- Popup menu: normal item.
    -- PmenuSel     { }, -- Popup menu: selected item.
    -- PmenuSbar    { }, -- Popup menu: scrollbar.
    -- PmenuThumb   { }, -- Popup menu: Thumb of the scrollbar.
    -- Question     { }, -- |hit-enter| prompt and yes/no questions
    -- QuickFixLine { }, -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    -- SpecialKey   { }, -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace| SpellBad  Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.  SpellCap  Word that should start with a capital. |spell| Combined with the highlighting used otherwise.  SpellLocal  Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
    -- SpellRare    { }, -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
    -- StatusLine   { }, -- status line of current window
    -- StatusLineNC { }, -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    -- TabLine      { }, -- tab pages line, not active tab page label
    -- TabLineFill  { }, -- tab pages line, where there are no labels
    -- TabLineSel   { }, -- tab pages line, active tab page label
    -- Title        { }, -- titles for output from ":set all", ":autocmd" etc.
    -- Visual       { }, -- Visual mode selection
    -- VisualNOS    { }, -- Visual mode selection when vim is "Not Owning the Selection".
    -- WarningMsg   { }, -- warning messages
    -- Whitespace   { }, -- "nbsp", "space", "tab" and "trail" in 'listchars'
    -- WildMenu     { }, -- current match in 'wildmenu' completion

    -- These groups are not listed as default vim groups,
    -- but they are defacto standard group names for syntax highlighting.
    -- commented out groups should chain up to their "preferred" group by
    -- default,
    -- Uncomment and edit if you want more specific syntax highlighting.

    -- Constant       { }, -- (preferred) any constant
    -- String         { }, --   a string constant: "this is a string"
    -- Character      { }, --  a character constant: 'c', '\n'
    -- Number         { }, --   a number constant: 234, 0xff
    -- Boolean        { }, --  a boolean constant: TRUE, false
    -- Float          { }, --    a floating point constant: 2.3e10

    -- Identifier     { }, -- (preferred) any variable name
    -- Function       { }, -- function name (also: methods for classes)

    -- Statement      { }, -- (preferred) any statement
    -- Conditional    { }, --  if, then, else, endif, switch, etc.
    -- Repeat         { }, --   for, do, while, etc.
    -- Label          { }, --    case, default, etc.
    -- Operator       { }, -- "sizeof", "+", "*", etc.
    -- Keyword        { }, --  any other keyword
    -- Exception      { }, --  try, catch, throw

    -- PreProc        { }, -- (preferred) generic Preprocessor
    -- Include        { }, --  preprocessor #include
    -- Define         { }, --   preprocessor #define
    -- Macro          { }, --    same as Define
    -- PreCondit      { }, --  preprocessor #if, #else, #endif, etc.

    -- Type           { }, -- (preferred) int, long, char, etc.
    -- StorageClass   { }, -- static, register, volatile, etc.
    -- Structure      { }, --  struct, union, enum, etc.
    -- Typedef        { }, --  A typedef

    -- Special        { }, -- (preferred) any special symbol
    -- SpecialChar    { }, --  special character in a constant
    -- Tag            { }, --    you can use CTRL-] on this
    -- Delimiter      { }, --  character that needs attention
    -- SpecialComment { }, -- special things inside a comment
    -- Debug          { }, --    debugging statements

    -- Underlined     { }, -- (preferred) text that stands out, HTML links

    -- ("Ignore", below, may be invisible...)
    -- Ignore         { }, -- (preferred) left blank, hidden  |hl-Ignore|

    -- Error          { }, -- (preferred) any erroneous construct

    -- Todo           { }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
  }
end)

-- export-external
--
-- Integrating Lush with other tools:
--
-- By default, lush() actually returns your theme in parsed form. You can
-- interact with it in much the same way as you can inside a lush-spec.
--
-- It's recommended that your lush theme file (i.e. this file), returns the
-- theme variable at its end. This allows for other themes to extend your
-- theme, be that to inhert a light style from a dark style, or to allow users
-- to make adjustments by preference.  (e.g. to fix comment colours if they are
-- colourblind, etc)
--
-- This looks something like:
--
--   local theme = lush(function()
--     return {
--       Normal { fg = hsl(0, 100, 50) },
--       CursorLine { Normal },
--     }
--   end)
--
--   theme.Normal.fg()                     -- returns table {h = h, s = s, l = l}
--   tostring(theme.Normal.fg)             -- returns "#hexstring"
--   tostring(theme.Normal.fg.lighten(10)) -- you can still modify colours, etc
--
-- Note:
--
-- "Linked" groups do not expose their colours, you can find the key
-- of their linked group via the 'link' key (may require chaining)
--
--   theme.CursorLine.fg() -- This is bad!
--   theme.CursorLine.link   -- = "Normal"
--
-- Also Note:
--
-- Most plugins expose their own Highlight groups, which *should be the primary
-- method for setting theme colours*, there are however some plugins that
-- require adjustments to a global or configuration variable.
--
-- To set a global variable, use neovims lua bridge,
--
--   vim.g.my_plugin.color_for_widget = tostring(theme.Normal.fg)
--
-- Exporting a lush theme for use without Lush
--
-- To easily export a lush theme, you may pass your theme to export_to_buffer()
-- which will open a blank buffer, filled with your compiled theme for
-- editing or distribution.
--
-- The easiest way to do this is by inserting the export_to_buffer() call at
-- the end of your theme, temporarily, then reloading your theme.
--
-- Caution: If you're theme file is currently lush.ify'd you may
--          spawn multiple buffers
--
--   theme = lush(...)
--
--   lush.export_to_buffer(theme)
--
-- Finally you can manually apply all stages, if you wish to inject something.
-- local parsed = lush.parse(lush_spec, options) -- table of spec
-- local compiled = lush.compile(parsed, options) -- table of cmd strings
-- lush.apply(compiled) -- runs cmds

-- return our parsed theme for extension or use else where.
return theme

-- vi:nowrap:cursorline:number
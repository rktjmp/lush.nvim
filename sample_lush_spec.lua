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
-- Copy it to your own <theme>/lua and edit, or open it and
-- follow the instructions to explor Lush.

-- First, enable lush.ify on this file, run
--
--   :lua require('lush').ify()
--
-- Calls to hsl() and highlight groups should now have appropriate
-- colours

-- You use the hsl lib to define colours
-- (or even require('lush.hsl') in other modules)

local lush = require('lush')
local hsl = lush.hsl

-- Try editing some of these values to see the colours update in real time.
--
-- Note: Some CursorLine highlighting will obscure any other
--       highlighing until you move your cursor to another line.
--
--       You can disable the CursorLine group temporarily with:
--
--       :hi! CursorLine NONE

local sea_foam = hsl(208, 80, 80);
local sea_crest = hsl(208, 90, 30);
local sea_deep = hsl(208, 90, 10);

-- Lush.hsl provides a number of conveniece functions for:
--
--   Relative adjustment (roatate(), saturate(), desaturate(), lighten(), darken())
--   Overrides           (hue(), saturation(), lightness())
--   Access              (.h, .s, .l)
--   Coercion            (tostring(), "Concatination: " .. color)
--

-- Lets find some harmonious colours from our original set.
-- (Unfortunately, deep inspection lushify highlighting is currently WIP.)

-- rotate 120 deg arond the colour wheel
local sea_foam_triadic = sea_foam.rotate(120)

-- rotate 180 degrees, darken and saturate the colour.
local sea_foam_compliment = sea_foam.rotate(180).darken(10).saturate(10)

-- Lets define our colourscheme via a lush spec.
--
-- We must pass a function to Lush, which returns a table containing
-- our spec. When called in this manner, Lush will automatically
-- process, clear any existing syntax and highlight groups, then apply our scheme.
--
-- If we don't want to do that, you can also call lush.create(spec)
-- which will return the spec as a list of nvim_command compatible
-- strings. You can call lush.apply(cmds) to apply or
-- lush.stringify(cmds) to convert the list ... TODO: Exporter

lush(function()
  return {
    -- Recommend you disable wrapping with `setlocal nowrap`.
    -- You may also receive (ignorable) linter/lsp warnings,
    -- as our lua is a bit more dynamic than they expect, so you
    -- may also wish to disable those while editing your theme.

    -- Uncomment the following lines and save the file, because we
    -- have called lush.ify(), our changes are hot reloaded.
    -- Notice how group names also have their highlighting applied
    -- for easy reference and creation.
    --
    -- Try saving the file now, to see vim in it's default state.

    -- Set a highlight group from hsl variables
    -- Normal       { bg = sea_deep, fg = sea_foam }, -- normal text
    -- Compose a highlight group from parts of another group
    -- CursorLine   { bg = Normal.bg.lighten(5), fg = Normal.fg.rotate(100) }, -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
    -- Link a highlight group to an existing group (must be in your lush-spec and above the link)
    -- CursorColumn { CursorLine },

    -- you can apply any gui, sp settings via strings
    -- (terminal support dependent)
    -- Comment      { fg = Normal.bg.desaturate(25).lighten(25), gui="italic" }, -- (preferred) any comment

    -- You can also use highlight groups to define colors if you don't want to use variables.
    -- They act much the same way. These groups will be defined in your vim runtime, but they will not
    -- have any matcher associated (outside of a lushify'd file).
    -- CamelCase is by tradition but you don't have to use it.

    -- search_base  { bg = hsl(52, 52, 52), fg = hsl(52, 10, 10) },
    -- Search       { search_base },
    -- IncSearch    { bg = search_base.bg.rotate(-20), fg = search_base.fg.darken(90) }

    -- The following are all the Neovim default highlight groups from
    -- docs as of 0.5.0-812.
    --
    -- Referenced groups must come before being referenced,
    -- (i.e. above we create Normal before trying to set CursorLine)
    -- so the order shown ((mostly) alphabetical) is likely
    -- not the order you will end up with.
    --
    -- You can uncomment them and leave them empty to disable any
    -- styling for that group (meaning they get styled as Normal)
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
    -- LineNr       { }, -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    -- CursorLineNr { }, -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
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
    -- commented out groups should chain up to their "preferred" group by default,
    -- uncomment and edit if you want more specific syntax highlighting.


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

    -- Ignore         { }, -- (preferred) left blank, hidden  |hl-Ignore|

    -- Error          { }, -- (preferred) any erroneous construct

    -- Todo           { }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
  }
end)

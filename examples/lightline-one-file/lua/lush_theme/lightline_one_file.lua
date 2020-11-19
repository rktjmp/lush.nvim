--
-- Built with,
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

-- This file shows how to style Lightline with Lush, using one file.
--
-- Enable lush.ify on this file, run:
--
--  `:Lushify`
--
--  or
--
--  `:lua require('lush').ify()`
--
-- Be sure to examine the accompaning colors/ vim file.

local lush = require('lush')
local hsl = lush.hsl

-- Minimal example lush-spec
local theme = lush(function()
  return {
    Normal       { bg = hsl(240,20, 10), fg = hsl(240, 30, 90) },
    CursorLine   { },
    Comment      { fg = Normal.fg.da(40).de(10), gui="italic"},
  }
end)

-- Define your lightline theme using groups from our lush spec
--
-- This theme simply flips the background and foreground colours
-- for normal and insert mode.
--
-- Continue below to see how to enable real time updating,
-- then try editing this theme.
local lightline_theme = {
   normal = {
     left = {
       {theme.Normal.fg.hex, theme.Normal.bg.hex},
     },
     middle = {
       {theme.Normal.fg.hex, theme.Normal.bg.hex},
     },
     right = {
       {theme.Normal.fg.hex, theme.Normal.bg.hex},
     },
   },
   insert = {
     left = {
       {theme.Normal.bg.hex, theme.Normal.fg.hex},
     },
     middle = {
       {theme.Normal.bg.hex, theme.Normal.fg.hex},
     },
     right = {
       {theme.Normal.bg.hex, theme.Normal.fg.hex},
     },
   },
 }

-- Use lightlines helper functions to correct cterm holes in our theme.
-- Note: These functions can be expensive to run, it is recommended you
--       leave them commented out until you wish to work on lightline,
--       or investigate the two-file approach in the other lightline example.
local lightline_theme_filled = vim.fn['lightline#colorscheme#fill'](lightline_theme)

-- define our theme for lightline to find
vim.g['lightline#colorscheme#lightline_one_file#palette'] = lightline_theme_filled

-- Technically, that's all you have to do for your lightline theme to
-- be applied but if you want real-time feedback while designing it, you must
-- include some extra code which forces lightline to notice the changes.
--
-- It's recommended you comment out the following code if you're not actively
-- editing your lightline theme.
--
-- You may find realtime performance unacceptable while changes are being
-- propagated back to and applied by vimscript, if this is a problem,
-- you can disable lush.ify() on the buffer (save then `:e!`), then when you
-- wish to preview your changes, save and run `:luafile %`.
--
-- Consider making a temporary mapping while working:
--
--   `:nmap <leader>llr :luafile %<CR>`

-- Lightline is a little tempermental about when you tell it to update it's
-- theme, so we push it to vim's scheduler.
vim.schedule(function()
  -- lightline#colorscheme() has a side effect of not always
  -- applying updates until after leaving insert mode.
  vim.fn['lightline#colorscheme']()

   -- this will apply more uniforming across all modes, but may have
   -- unacceptable performance impacts.
   -- vim.fn['lightline#disable']()
   -- vim.fn['lightline#enable']()
end)

return theme

-- vi:nowrap:cursorline:number

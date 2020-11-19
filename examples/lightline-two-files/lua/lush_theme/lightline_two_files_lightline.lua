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

-- This file shows how to style Lightline with Lush, using two files.
--
-- This is the lightline theme file.
--
-- This theme simply flips the background and foreground colours
-- for normal and insert mode.
--
-- Continue below to see how to enable real time updating,
-- then try editing this theme.

-- You may remember that lush converts our themes a table, and
-- when we return that table it can act as a lua module.
--
-- This allows us to import a fully parsed spec for use in other
-- lua code.
--
-- Enable lush.ify on this file, run:
--
--  `:Lushify`
--
--  or
--
--  `:lua require('lush').ify()`
--
-- Import our main theme definitions
local theme = require('lush_theme.lightline_two_files')

-- Use the imported theme. If you've looked at lightine_one_file, this will
-- look very familiar, indeed, you only have to cut-paste the lightline
-- code and make sure you import the main theme file.
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
local lightline_theme_filled = vim.fn['lightline#colorscheme#fill'](lightline_theme)

-- define our theme for lightline to find
vim.g['lightline#colorscheme#lightline_two_files#palette'] = lightline_theme_filled

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
  -- vim.fn['lightline#colorscheme']()

   -- this will apply more uniforming across all modes, but may have
   -- unacceptable performance impacts.
   -- vim.fn['lightline#disable']()
   -- vim.fn['lightline#enable']()
end)


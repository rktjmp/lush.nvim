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
-- By separating lightline into it's own file, we can alleviate some
-- performance issues, if they are a problem.
--
-- It's up to you which style you choose, it's probably
-- simpler to start with one file then transition to two,
-- which is relatively painless to do.
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
-- this is all we have to do here.
return lush(function()
  return {
    Normal       { bg = hsl(120,20, 10), fg = hsl(120, 30, 90) },
    CursorLine   { },
    Comment      { fg = Normal.fg.da(20).de(10), gui="italic"},
  }
end)

-- vi:nowrap:cursorline:number

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

-- Lush-specs are closures, executed in a clean environment. This means they
-- cannot access regular Lua globals or modules unless you bind those modules
-- to a local variable.
--
-- You could use this to for example, set your background color depending on
-- an external api such as weather, build status, etc or inject another theme
-- to use it's colors in a new theme (maybe your light and dark pair)
--
-- Note that the values are set only once, on load, so in the build status
-- example, you would have to set some additional autocmds to reload your
-- theme on external events.
--

local lush = require('lush')
local hsl = lush.hsl
local dark =require('lush_theme.my_theme_dark')
local math = math -- locally bind math global

local theme = lush(function()
  return {
    Normal { fg = hsl(100, 50, math.random(30, 60)) },
    CursorLine { fg = dark.CursorLine.bg.li(30) },
  }
end)

-- return our parsed theme for extension or use else where.
return theme

-- vi:nowrap:cursorline:number

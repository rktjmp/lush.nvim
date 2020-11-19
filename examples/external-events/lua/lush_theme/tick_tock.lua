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

local lush = require('lush')
local hsl = lush.hsl

-- this may be anything, query a file, etc.
-- it will be run on the main thread, so if you expect your operation to be
-- expensive you should make your data source async and cacheing
-- You cound instead check for the precense of a file (test pass or fail?)
-- or local weather, or ...

local second = os.date("*t").sec

local theme = lush(function()
  return {
    TimeColor { fg = hsl(360 * (second / 60), 50, 20) },
    Normal { fg = TimeColor.fg, bg = TimeColor.fg.ro(240).li(50) },
  }
end)

-- return our parsed theme for extension or use else where.
return theme

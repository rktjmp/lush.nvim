--
-- Built with,
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

-- Lush-specs are executed in a clean environment, which means they do not
-- have access to regular or external Lua functions.
--
-- If you do need access, you can inject modules or functions by passing
-- a table to lush, after your spec.
--
-- lush(spec, {my_mod: require('my_mod'), random: math.random})
--
-- You could use this to for example, set your background color depending on
-- an external api such as weather, build status, etc.
--
-- Note that the values are set only once, on load, so in the build status
-- example, you would have to set some additional autocmds to reload your
-- theme.
--


local lush = require('lush')
local hsl = lush.hsl

local theme = lush(function()
  return {
    Normal { fg = hsl(100, 50, math.random(30, 60)) },
  }
end, {math = math})

-- return our parsed theme for extension or use else where.
return theme

-- vi:nowrap:cursorline:number

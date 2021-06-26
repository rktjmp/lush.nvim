local hsluv_convert = require('lush.vivid.hsluv.convert')
local hsl_like = require('lush.vivid.hsl_like')

--
-- HSLUV Color
--
-- expects to be called as hsluv(hue, sat, light) or hslulv("#RRGGBB")
--

local type_fns = {
  from_hex = hsluv_convert.hex_to_hsl,
  to_hex = hsluv_convert.hsl_to_hex,
  name = function() return "hsluv()" end
}

return function(h_or_hex, s, l)
  return hsl_like(h_or_hex, s, l, type_fns)
end

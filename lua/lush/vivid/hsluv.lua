local hsluv_convert = require('lush.vivid.hsluv.convert')
local hsl_like = require('lush.vivid.hsl_like')

--
-- HSLUV Color
--
-- expects to be called as hsluv(hue, sat, light) or hslulv("#RRGGBB")
--

-- handle hsluv(h, s, l)
local function hsluv_from_hsluv(h,s,l)
  return hsl_like({h = h, s = s, l = l}, hsluv_convert.hsluv_to_hex)
end

-- handle hsl("#RRGGBB")
local function hsluv_from_hex(str)
  local converted = hsluv_convert.hex_to_hsluv(str)
  return hsl_like({
    h = converted.h,
    s = converted.s,
    l = converted.l,
  }, hsluv_convert.hsluv_to_hex)
end

return function(h_or_hex, s, l)
  assert(h_or_hex, "hsl() expects (number, number, number) or (string)")
  local h, hex = h_or_hex, h_or_hex

  if type(hex) == "string" then
    return hsluv_from_hex(hex)
  else
    if type(h) ~= "number" or
        type(s) ~= "number" or
        type(l) ~= "number" then
      error( "hsl() expects (number, number, number) or (string)", 2)
    end
    return hsluv_from_hsluv(h, s, l)
  end
end

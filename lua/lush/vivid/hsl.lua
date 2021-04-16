local convert = require('lush.hsl.convert')
local hsl_like = require('lush.vivid.hsl_like')

--
-- HSL Color
--
-- expects to be called as hsl(hue, sat, light) or hsl("#RRGGBB")
--

-- handle hsl(h, s, l)
local function hsl_from_hsl(h,s,l)
  return hsl_like({h = h, s = s, l = l}, convert.hsl_to_hex)
end

-- handle hsl("#RRGGBB")
local function hsl_from_hex(str)
  local converted = convert.hex_to_hsl(str)
  return hsl_like({
    h = converted.h,
    s = converted.s,
    l = converted.l,
  }, convert.hsl_to_hex)
end

return function(h_or_hex, s, l)
  assert(h_or_hex, "hsl() expects (number, number, number) or (string)")
  local h, hex = h_or_hex, h_or_hex

  if type(hex) == "string" then
    return hsl_from_hex(hex)
  else
    if type(h) ~= "number" or
        type(s) ~= "number" or
        type(l) ~= "number" then
      error( "hsl() expects (number, number, number) or (string)", 2)
    end
    return hsl_from_hsl(h, s, l)
  end
end

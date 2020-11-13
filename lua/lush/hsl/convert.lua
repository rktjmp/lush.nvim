local function hsl_to_rgb(h, s, l)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    local function hue2rgb(p, q, t)
      if t < 0   then t = t + 1 end
      if t > 1   then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return r * 255, g * 255, b * 255
end

local function rgb_to_hex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

local M = {}

M.hsl_to_hex = function(hsl)
    local h,s,l = hsl.h, hsl.s, hsl.l
    h = h / 360
    s = s / 100
    l = l / 100
    local r,g,b = hsl_to_rgb(h, s, l)
    return rgb_to_hex(r, g, b)
end

return M

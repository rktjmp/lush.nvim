local convert = require('lush.hsl.convert')

local function hsl_clamp(color)
  return {
    h = (color.h % 360),
    s = math.min(100, math.max(0, color.s)),
    l = math.min(100, math.max(0, color.l)),
  }
end

local function wrap_color(color)
  -- make sure our color is valid
  color = hsl_clamp(color)

  local roll_fn = function(color, key, negate)
    -- negate -> darken -> -val
    negate = negate and -1 or 1
    return function(val)
      local new_color = {h = color.h, s = color.s, l = color.l}
      new_color[key] = new_color[key] + (val * negate)
      return wrap_color(new_color)
    end
  end

  local roll_rel_fn = function(color, key, negate)
    -- negate -> darken -> -val
    negate = negate and -1 or 1
    return function(val)
      local new_color = {h = color.h, s = color.s, l = color.l}
      new_color[key] = new_color[key] + (new_color[key] * (val/100) * negate)
      return wrap_color(new_color)
    end
  end

  local rotate = function(color)
    return roll_fn(color, "h")
  end

  local rotate_rel = function(color)
    -- doesn't really make sense to relatively rotate a hue,
    -- relatively rotate 0 (red) is always red, green swings more than blue
    -- etc.
    error("hsl.rotate_rel is an unsupported operation, use rotate()", 2)
  end

  local lighten = function(color)
    return roll_fn(color, "l")
  end
  local lighten_rel = function(color)
    return roll_rel_fn(color, "l")
  end

  local darken = function(color)
    return roll_fn(color, "l", true)
  end
  local darken_rel = function(color)
    return roll_rel_fn(color, "l", true)
  end

  local saturate = function(color)
    return roll_fn(color, "s")
  end
  local saturate_rel = function(color)
    return roll_rel_fn(color, "s")
  end

  local desaturate = function(color)
    return roll_fn(color, "s", true)
  end
  local desaturate_rel = function(color)
    return roll_rel_fn(color, "s", true)
  end

  local hue = function(color)
    return function(hue)
      return wrap_color({h = hue, s = color.s, l = color.l})
    end
  end
  local saturation = function(color)
    return function(saturation)
      return wrap_color({h = color.h, s = saturation, l = color.l})
    end
  end
  local lightness = function(color)
    return function(lightness)
      return wrap_color({h = color.h, s = color.s, l = lightness})
    end
  end

  local mod_fns = {
    rotate = rotate,
    rotate_rel = rotate_rel,
    ro = rotate,
    ror = rotate_rel,

    saturate = saturate,
    saturate_rel = saturate_rel,
    sa = saturate,
    sar = saturate_rel,

    desaturate = desaturate,
    desaturate_rel = desaturate_rel,
    de = desaturate,
    der = desaturate_rel,

    lighten = lighten,
    lighten_rel = lighten_rel,
    li = lighten,
    lir = lighten_rel,

    darken = darken,
    darken_rel = darken_rel,
    da = darken,
    dar = darken_rel,

    hue = hue,
    saturation = saturation,
    lightness = lightness
  }

  return setmetatable({}, {
    -- it's hsl colors all the way down
    __index = function(_, key_name)
      if key_name == "h" then return color.h end
      if key_name == "s" then return color.s end
      if key_name == "l" then return color.l end
      if key_name == "hex" then return convert.hsl_to_hex(color) end

      if mod_fns[key_name] then
        return mod_fns[key_name](color)
      else
        local ops = ""
        for op, _ in pairs(mod_fns) do
          ops = ops .. " " .. op
        end
        error("Invalid hsl operation: '"
              .. key_name
              .. "', valid operations:"
              .. ops, 2)
      end
    end,

    -- possibly this won't be useless, but for now disable
    __newindex = function(table, key, value)
      error('Member setting disabled', 2)
    end,

    __tostring = function(hsl)
      return convert.hsl_to_hex(hsl)
    end,

    __concat = function(lhs, rhs)
      return tostring(lhs) .. tostring(rhs)
    end,

    -- if we call, return the raw value
    __call = function()
      return color
    end
  })
end

local function hsl_from_hsl(h,s,l)
  return wrap_color({h = h, s = s, l = l})
end

local function hsl_from_hex(str)
  local converted = convert.hex_to_hsl(str)
  return wrap_color({
    h = converted.h,
    s = converted.s,
    l = converted.l,
  })
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

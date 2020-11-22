local convert = require('lush.hsl.convert')

local function hsl_clamp(color)
  local clamp = function(val, min, max)
    return math.min(max, math.max(min, val))
  end
  local round = function(val)
    return math.floor(val + 0.5)
  end
  local h, s, l
  h = color.h % 360
  s = round(clamp(color.s, 0, 100))
  l = round(clamp(color.l, 0, 100))
  return { h = h, s = s, l = l }
end

local function wrap_color(color)
  -- make sure our color is valid
  color = hsl_clamp(color)

  local roll_abs_fn = function(color, key)
    return function(abs_value)
      if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      local new_color = {h = color.h, s = color.s, l = color.l}
      new_color[key] = new_color[key] + abs_value
      return wrap_color(new_color)
    end
  end

  local roll_lerp_fn = function(color, key)
    return function(percent)
      if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end

      -- we never modifiy the caller
      local new_color = {h = color.h, s = color.s, l = color.l}
      -- we can safely bounds all relative adjustments to 0, 100
      -- because you can't 'relatively rotate' hue
      local min, max = 0, 100
      -- we want to lerp between the current value, and the potential largest
      -- change for -percent this is [0, current], +percent, [0, max - current]
      local lerp_space = percent < 0 and new_color[key] or (max - new_color[key])
      -- perform the lerp
      new_color[key] = new_color[key] + (lerp_space * (percent / 100))
      return wrap_color(new_color)
    end
  end

  local rotate = function(color)
    return roll_abs_fn(color, "h")
  end

  local saturate = function(color)
    return roll_lerp_fn(color, "s")
  end
  local abs_saturate = function(color)
    return roll_abs_fn(color, "s")
  end

  local desaturate = function(color)
    return function(percent)
      if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return roll_lerp_fn(color, "s")(-percent)
    end
  end
  local abs_desaturate = function(color)
    return function(abs_value)
      if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return roll_abs_fn(color, "s")(-abs_value)
    end
  end

  local lighten = function(color)
    return roll_lerp_fn(color, "l")
  end
  local abs_lighten = function(color)
    return roll_abs_fn(color, "l")
  end

  local darken = function(color)
    return function(percent)
      if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return roll_lerp_fn(color, "l")(-percent)
    end
  end
  local abs_darken = function(color)
    return function(abs_value)
      if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return roll_abs_fn(color, "l")(-abs_value)
    end
  end


  local hue = function(color)
    return function(hue)
      if type(hue) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return wrap_color({h = hue, s = color.s, l = color.l})
    end
  end
  local saturation = function(color)
    return function(saturation)
      if type(saturation) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return wrap_color({h = color.h, s = saturation, l = color.l})
    end
  end
  local lightness = function(color)
    return function(lightness)
      if type(lightness) ~= "number" then error("Must provide number to HSL modifiers", 0) end
      return wrap_color({h = color.h, s = color.s, l = lightness})
    end
  end

  local mod_fns = {
    rotate = rotate,
    ro = rotate,

    saturate = saturate,
    sa = saturate,
    abs_saturate = abs_saturate,
    abs_sa = abs_saturate,

    desaturate = desaturate,
    de = desaturate,
    abs_desaturate = abs_desaturate,
    abs_de = abs_desaturate,

    lighten = lighten,
    li = lighten,
    abs_lighten = abs_lighten,
    abs_li = abs_lighten,

    darken = darken,
    da = darken,
    abs_darken = abs_darken,
    abs_da = abs_darken,

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

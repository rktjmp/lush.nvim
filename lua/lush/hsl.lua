local convert = require('lush.hsl.convert')

local function hsl_rotate(color, amount)
  return {
    h = (color.h + amount) % 360,
    s = color.s,
    l = color.l,
  }
end

local function hsl_lighten(color, amount)
  return {
    h = color.h,
    s = color.s,
    l = math.min(100, math.max(0, color.l + amount)),
  }
end

local function hsl_saturate(color, amount)
  return {
    h = color.h,
    s = math.min(100, math.max(0, color.s + amount)),
    l = color.l,
  }
end


local function wrap_color(color)
  local rotate = function(color)
    return function(amount)
      return wrap_color(hsl_rotate(color, amount))
    end
  end
  local lighten = function(color)
    return function(amount)
      return wrap_color(hsl_lighten(color, amount))
    end
  end
  local darken = function(color)
    return function(amount)
      return wrap_color(hsl_lighten(color, -amount))
    end
  end
  local saturate = function(color)
    return function(amount)
      return wrap_color(hsl_saturate(color, amount))
    end
  end
  local desaturate = function(color)
    return function(amount)
      return wrap_color(hsl_saturate(color, -amount))
    end
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
    ro = rotate,
    saturate = saturate,
    sa = saturate,
    desaturate = desaturate,
    de = desaturate,
    lighten = lighten,
    li = lighten,
    darken = darken,
    da = darken,
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
        error('Invalid HSL operation: '
              .. key_name
              .. ", valid operations:"
              .. ops)
      end
    end,

    -- possibly this won't be useless, but for now disable
    __newindex = function(table, key, value)
      error('Member setting disabled')
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
  local color = wrap_color({h = 0, s = 0, l = 0})
  -- set via helpers to run bounds checking
  return color.rotate(h).saturate(s).lighten(l)
end

local function hsl_from_hex(str)
  local color = wrap_color({h = 0, s = 0, l = 0})
  local converted = convert.hex_to_hsl(str)
  -- set via helpers to run bounds checking
  return color.rotate(converted.h)
              .saturate(converted.s)
              .lighten(converted.l)
end

return function(h_or_hex, s, l)
  if type(h_or_hex) == "string" then
    return hsl_from_hex(h_or_hex)
  else
    return hsl_from_hsl(h_or_hex, s, l)
  end
end

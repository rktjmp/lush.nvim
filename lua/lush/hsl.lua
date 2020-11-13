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
  local mod_fns = {
    rotate = function(color)
      return function(amount)
        return wrap_color(hsl_rotate(color, amount))
      end
    end,
    lighten = function(color)
      return function(amount)
        return wrap_color(hsl_lighten(color, amount))
      end
    end,
    darken = function(color)
      return function(amount)
        return wrap_color(hsl_lighten(color, -amount))
      end
    end,
    saturate = function(color)
      return function(amount)
        return wrap_color(hsl_saturate(color, amount))
      end
    end,
    desaturate = function(color)
      return function(amount)
        return wrap_color(hsl_saturate(color, -amount))
      end
    end,
    hue = function(color)
      return function(hue)
        return wrap_color({h = hue, s = color.s, l = color.l})
      end
    end,
    saturation = function(color)
      return function(saturation)
        return wrap_color({h = color.h, s = saturation, l = color.l})
      end
    end,
    lightness = function(color)
      return function(lightness)
        return wrap_color({h = color.h, s = color.s, l = lightness})
      end
    end
  }

  return setmetatable({}, {
    -- it's hsl colors all the way down
    __index = function(_, key_name)
      if key_name == "h" then return color.h end
      if key_name == "s" then return color.s end
      if key_name == "l" then return color.l end
      if key_name == "as_hex" then return convert.hsl_to_hex(color) end
      if key_name == "as_table" then return color end

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

    __concat = function(op1, op2)
      -- Kind of brittle check (?) but its ... ok, our usecase is small
      if type(op1) == "table" then
        return convert.hsl_to_hex(op1) .. op2
      else
        return  op1 .. convert.hsl_to_hex(op2)
      end
    end,

    -- if we call, return the raw value
    __call = function()
      return color
    end
  })
end

local function hsl(h,s,l)
  local color = wrap_color({h = 0, s = 0, l = 0})
  -- set via helpers to run bounds checking
  return color.rotate(h).saturate(s).lighten(l)
end

return hsl

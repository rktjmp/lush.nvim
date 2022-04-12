local clamp = require('lush.math').clamp
local round = require('lush.math').round

--
-- HSL-like colour functions
--
-- Vivid supports both HSL and HSLuv colourspaces, which functionally
-- behave the same except when they are converting out into RGB.
--
-- This module provides common operations on hsl-like colours.
--

local function hsl_clamp(color)
  local h, s, l
  h = round(color.h % 360)
  s = round(clamp(color.s, 0, 100))
  l = round(clamp(color.l, 0, 100))
  return { h = h, s = s, l = l }
end

-- (color, key) -> (value) -> {h, s, l}
-- Given a color and key (h, s or l), returns a function which accepts a value which will
-- return a new color with the key set to given value
local function make_abs_fn(color, key)
  return function(abs_value)
    if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    local new_values = {h = color.h, s = color.s, l = color.l}
    new_values[key] = new_values[key] + abs_value
    return new_values
  end
end

-- (color, key) -> (value) -> {h, s, l}
-- Given a color and key (h, s or l), returns a function which accepts a value which will
-- return a new color with the key lerped by given value
local function make_lerp_fn(color, key)
  return function(percent)
    if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end

    -- we never modifiy the caller
    local new_values = {h = color.h, s = color.s, l = color.l}
    -- we can safely bounds all relative adjustments to 0, 100
    -- because you can't 'relatively rotate' hue
    local min, max = 0, 100
    -- we want to lerp between the current value, and the potential largest
    -- change for -percent this is [0, current], +percent, [0, max - current]
    local lerp_space = percent < min and new_values[key] or (max - new_values[key])
    -- perform the lerp
    new_values[key] = new_values[key] + (lerp_space * (percent / 100))
    return new_values
  end
end

-- (color) -> (n) -> {h + n, s, l}
local function op_rotate(color)
  return make_abs_fn(color, "h")
end

-- (color) -> (n) -> {h, s lerp n, l}
local function op_saturate(color)
  return make_lerp_fn(color, "s")
end

-- (color) -> (n) -> {h, s + n, l}
local function op_abs_saturate(color)
  return make_abs_fn(color, "s")
end

-- (color) -> (n) -> {h, s lerp -n, l}
local function op_desaturate(color)
  return function(percent)
    if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return make_lerp_fn(color, "s")(-percent)
  end
end

-- (color) -> (n) -> {h, s - n, l}
local function op_abs_desaturate(color)
  return function(abs_value)
    if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return make_abs_fn(color, "s")(-abs_value)
  end
end

-- (color) -> (n) -> {h, s, l lerp n}
local function op_lighten(color)
  return make_lerp_fn(color, "l")
end

-- (color) -> (n) -> {h, s, l + n}
local function op_abs_lighten(color)
  return make_abs_fn(color, "l")
end

-- (color) -> (n) -> {h, s, l lerp -n}
local function op_darken(color)
  return function(percent)
    if type(percent) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return make_lerp_fn(color, "l")(-percent)
  end
end

-- (color) -> (n) -> {h, s, l - n}
local function op_abs_darken(color)
  return function(abs_value)
    if type(abs_value) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return make_abs_fn(color, "l")(-abs_value)
  end
end

-- mix ref:
-- https://stackoverflow.com/questions/35816179/calculation-algorithm-to-mix-3-hsl-colors
-- (color) -> (color, n) -> {h x h x n, s x s x n, l x l x n}
local function op_mix(color)
  return function(target, strength)
    assert(strength, "must provide strength to mix")
    strength = clamp(strength, 0, 100) / 100
    -- strength of 0 means no mix towards target, so
    -- color vector strength is 1
    local cv_str = (1 - strength)
    -- target strength is the remainder, so
    -- str = 0, cv_str = 1, tv_str = 0
    -- str = 100, cv_str = 0, tv_str = 1
    local tv_str = 1 - cv_str

    -- convert colors to vector
    local cv = {
      x = math.cos(color.h / 180 * math.pi) * color.s,
      y = math.sin(color.h / 180 * math.pi) * color.s,
      z = color.l
    }
    local tv = {
      x = math.cos(target.h / 180 * math.pi) * target.s,
      y = math.sin(target.h / 180 * math.pi) * target.s,
      z = target.l
    }
    -- combine
    local rv = {
      x = ((cv.x * cv_str) + (tv.x * tv_str)) / 1,
      y = ((cv.y * cv_str) + (tv.y * tv_str)) / 1,
      z = ((cv.z * cv_str) + (tv.z * tv_str)) / 1,
    }
    -- back to color
    local new_values = {
      h = math.atan2(rv.y, rv.x) * (180 / math.pi),
      s = math.sqrt(rv.x * rv.x + rv.y * rv.y),
      l = rv.z
    }
    return new_values
  end
end

-- (color) -> (n) -> {n, s, l}
local function op_hue(color)
  return function(hue)
    if type(hue) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return {h = hue, s = color.s, l = color.l}
  end
end

-- (color) -> (n) -> {h, n, l}
local function op_saturation(color)
  return function(saturation)
    if type(saturation) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return {h = color.h, s = saturation, l = color.l}
  end
end

-- (color) -> (n) -> {h, s, n}
local function op_lightness(color)
  return function(lightness)
    if type(lightness) ~= "number" then error("Must provide number to HSL modifiers", 0) end
    return {h = color.h, s = color.s, l = lightness}
  end
end

-- (color) -> (n) -> {h, s, 0 | 100}
local function op_readable(color)
  return function()
    if color.l >= 50 then
      return {h = color.h, s = color.s, l = 0}
    else
      return {h = color.h, s = color.s, l = 100}
    end
  end
end

local function decorate_hsl_table(color, to_hex_fn)
  -- make sure our color is valid
  color = hsl_clamp(color)

  local op_fns = {
    rotate = op_rotate,
    ro = op_rotate,

    saturate = op_saturate,
    sa = op_saturate,
    abs_saturate = op_abs_saturate,
    abs_sa = op_abs_saturate,

    desaturate = op_desaturate,
    de = op_desaturate,
    abs_desaturate = op_abs_desaturate,
    abs_de = op_abs_desaturate,

    lighten = op_lighten,
    li = op_lighten,
    abs_lighten = op_abs_lighten,
    abs_li = op_abs_lighten,

    darken = op_darken,
    da = op_darken,
    abs_darken = op_abs_darken,
    abs_da = op_abs_darken,

    mix = op_mix,
    readable = op_readable,

    hue = op_hue,
    saturation = op_saturation,
    lightness = op_lightness,
  }

  return setmetatable({}, {
    -- it's hsl colors all the way down
    __index = function(_, key_name)
      if key_name == "h" then return color.h end
      if key_name == "s" then return color.s end
      if key_name == "l" then return color.l end
      if key_name == "hsl" then return {h = color.h, s = color.s, l = color.l} end
      if key_name == "hex" then return to_hex_fn(color) end
      if key_name == "rgb" then
        local hex = to_hex_fn(color)
        local cnv = require("lush.vivid.rgb.convert")
        return cnv.hex_to_rgb(hex)
      end

      -- look up requested key in operations table and call out
      -- if it exists, else try to show a nice warning.
      if op_fns[key_name] then
        return function(...)
          local altered_color = op_fns[key_name](color)(...)
          return decorate_hsl_table(altered_color, to_hex_fn)
        end
      else
        local ops = ""
        for op, _ in pairs(op_fns) do
          ops = ops .. " " .. op
        end
        ops = ops .. " h s l hex hsl"
        error("Invalid hsl operation: '"
        .. key_name
        .. "', valid operations:"
        .. ops, 2)
      end
    end,

    -- possibly this won't be useless, but for now disable
    __newindex = function(_, _, _)
      error('Member setting disabled', 2)
    end,

    __tostring = function(hsl)
      return to_hex_fn(hsl)
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

local M = function(h_or_hex, s, l, type_fns)
  assert(type_fns, "must provide type_fns")
  assert(type_fns.name, "must provide name() type_fn")
  assert(type_fns.from_hex, type_fns.name() .. " must provide from_hex() type_fn")
  assert(type_fns.to_hex, type_fns.name() .. " must provide to_hex() type_fn")

  assert(h_or_hex, type_fns.name() .. " expects (number, number, number) or (string)")

  local h, hex_str = h_or_hex, h_or_hex
  local hsl

  if type(hex_str) == "string" then
    -- normalise
    local hex = "[abcdef0-9][abcdef0-9]"
    local pat = "^#("..hex..")("..hex..")("..hex..")$"
    hex_str = string.lower(hex_str)

    -- smoke test
    assert(string.find(hex_str, pat) ~= nil,
           "hex_to_rgb: invalid hex_str: " .. tostring(hex_str))

     hsl = type_fns.from_hex(hex_str)
  else
    if type(h) ~= "number" or
        type(s) ~= "number" or
        type(l) ~= "number" then
      error(type_fns.name() .. " expects (number, number, number) or (string)", 2)
    end
    hsl = {h = h, s = s, l = l}
  end

  return decorate_hsl_table(hsl, type_fns.to_hex)
end

return M

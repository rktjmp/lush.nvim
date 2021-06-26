-- Support module to convert between RGB and HEX

local function rgb_to_hex(rgb)
  return string.format("#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
end

local function hex_to_rgb(hex_str)
  -- normalise
  local hex = "[abcdef0-9][abcdef0-9]"
  local pat = "^#("..hex..")("..hex..")("..hex..")$"
  hex_str = string.lower(hex_str)

  -- smoke test
  assert(string.find(hex_str, pat) ~= nil,
         "hex_to_rgb: invalid hex_str: " .. tostring(hex_str))

  -- convert
  local r,g,b = string.match(hex_str, pat)
  r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)

  return {r = r, g = g, b =  b}
end

local M = {
  rgb_to_hex = rgb_to_hex,
  hex_to_rgb = hex_to_rgb
}

return M

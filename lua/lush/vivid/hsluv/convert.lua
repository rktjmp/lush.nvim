-- Support module to convert between HSL and RGB_HEX values
--
-- Work actually performed by hsluv lib

local lib = require("lush.vivid.hsluv.lib")
-- small 5.2+ compat so we can require elsewhere
local unpack = unpack or table.unpack

local M = {
  hex_to_hsluv = function(hex)
    local h, s, l = unpack(lib.hex_to_hsluv(hex))
    return {h = h, s = s, l = l}
  end,
  hsluv_to_hex = function(color)
    return lib.hsluv_to_hex({color.h, color.s, color.l})
  end
}

return M

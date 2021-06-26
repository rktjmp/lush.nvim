-- tiny wrapper to convert between library representation and our representation
local hsluv = require("lush.vivid.hsluv.lib")

local M = {
  hex_to_hsluv = function(hex)
    local h, s, l = unpack(hsluv.hex_to_hsluv(hex))
    return {h = h, s = s, l = l}
  end,
  hsluv_to_hex = function(color)
    return hsluv.hsluv_to_hex({color.h, color.s, color.l})
  end
}
return M

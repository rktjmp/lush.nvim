-- TEMPORARY be-nice patch for misbehaving npxbr/gruvbox.nvim
local convert = require("lush.vivid.hsl.convert")

return {
  hsl_to_hex = convert.hsl_to_hex
}

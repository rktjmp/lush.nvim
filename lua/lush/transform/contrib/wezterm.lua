--- wezterm transform, expects a table in the shape:
--
-- @param colors {
--   fg = "#000000",
--   bg = "#000000",
--   cursor_fg = "#000000",
--   cursor_bg = "#000000",
--   cursor_border = "#000000",
--   selection_fg = "#000000",
--   selection_bg = "#000000",
--   black = "#000000",
--   red = "#000000",
--   green = "#000000",
--   yellow = "#000000",
--   blue = "#000000",
--   magenta = "#000000",
--   cyan = "#000000",
--   white = "#000000",
--   bright_black = "#000000",
--   bright_red = "#000000",
--   bright_green = "#000000",
--   bright_yellow = "#000000",
--   bright_blue = "#000000",
--   bright_magenta = "#000000",
--   bright_cyan = "#000000",
--   bright_white = "#000000",
-- }

local helpers = require("lush.transform.helpers")
local check_keys = {
  "fg", "bg",
  "cursor_fg", "cursor_bg", "cursor_border",
  "selection_fg", "selection_bg",
  "black", "red", "green", "yellow", "blue",
  "magenta", "cyan", "white",
  "bright_black", "bright_red", "bright_green", "bright_yellow", "bright_blue",
  "bright_magenta", "bright_cyan", "bright_white",
}

local template = [[
[colors]
foreground    = "$fg"
background    = "$bg"
cursor_fg     = "$cursor_fg"
cursor_bg     = "$cursor_bg"
cursor_border = "$cursor_border"
selection_fg  = "$selection_fg"
selection_bg  = "$selection_bg"
ansi = ["$black", "$red", "$green", "$yellow", "$blue", "$magenta", "$cyan", "$white"]
brights = ["$bright_black", "$bright_red", "$bright_green", "$bright_yellow", "$bright_blue", "$bright_magenta", "$bright_cyan", "$bright_white"]
]]

local function transform(colors)
  for _, key in ipairs(check_keys) do
    assert(colors[key],
      "wezterm colors table missing key: " .. key)
  end
  return helpers.split_newlines(helpers.apply_template(template, colors))
end

return transform

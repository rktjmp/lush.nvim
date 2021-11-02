-- ###########################
--
-- THIS TEMPLATE IS CURRENTLY INCOMPLETE
--
-- ###########################
--
--- kitty transform, expects a table in the shape:
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
--
-- https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/template.conf
--

local template = [[
background $bg
foreground $fg
cursor     $cursor_fg
url_color  $url
selection_background    $selection_fg
selection_foreground    $selection_bg
tab_bar_background      $overbg
active_tab_background   $overbg
active_tab_foreground   $yellow
inactive_tab_background $overbg
inactive_tab_foreground $faded
color0  $black
color1  $red
color2  $green
color3  $yellow
color4  $blue
color5  $magenta
color6  $cyan
color7  $white
color8  $bright_black
color9  $bright_red
color10 $bright_green
color11 $bright_yellow
color12 $bright_blue
color13 $bright_magenta
color14 $bright_cyan
color15 $bright_white]]

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

local function transform(colors)
  for _, key in ipairs(check_keys) do
    assert(colors[key],
      "kitty colors table missing key: " .. key)
  end
  return helpers.split_newlines(helpers.apply_template(template, colors))
end

return transform

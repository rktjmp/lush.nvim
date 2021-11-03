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
--
--   Optionally any of:
--
--   url = "#000000",
--   border_active = "#000000",
--   border_inactive = "#000000",
--   border_bell = "#000000",
--   titlebar = "#000000",
--   tab_active_fg = "#000000",
--   tab_active_bg = "#000000",
--   tab_inactive_fg = "#000000",
--   tab_inactive_bg = "#000000",
--   tab_bg = "#000000",
--   mark1_fg = "#000000",
--   mark1_bg = "#000000",
--   mark2_fg = "#000000",
--   mark2_bg = "#000000",
--   mark3_fg = "#000000",
--   mark3_bg = "#000000",
--   name = "Theme Name",
--   author = "Your Name",
--   license = "Theme Licence",
--   upstream = "Theme URL",
--   blurb = "Theme Blurb",
-- }

-- NB: Lines with "$" in them are stripped from the final output, this
--     allows the transform user to not have to specify everything.
-- https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/template.conf
local template = [[
# vim:ft=kitty
# This is a template that can be used to create new kitty themes$
# Theme files should start with a metadata block consisting of$
# lines beginning with ##. All metadata fields are optional.$

## name: $name
## author: $author
## license: $license
## upstream: $upstream
## blurb: $blurb

# All the settings below are colors, which you can choose to modify, or use the$
# defaults. You can also add non-color based settings if needed but note that$
# these will not work with using kitty @ set-colors with this theme. For a reference$
# on what these settings do see https://sw.kovidgoyal.net/kitty/conf/$

# The basic colors$
foreground                      $fg
background                      $bg
selection_foreground            $selection_fg
selection_background            $selection_bg

# Cursor colors
cursor                          $cursor_bg
cursor_text_color               $cursor_fg

# URL underline color when hovering with mouse
url_color                       $url

# kitty window border colors
active_border_color             $border_active
inactive_border_color           $border_inactive
bell_border_color               $border_bell

# OS Window titlebar colors
wayland_titlebar_color $titlebar
macos_titlebar_color $titlebar

# Tab bar colors
active_tab_foreground           $tab_active_fg
active_tab_background           $tab_active_bg
inactive_tab_foreground         $tab_inactive_fg
inactive_tab_background         $tab_inactive_bg
tab_bar_background              $tab_bg

# Colors for marks (marked text in the terminal)

mark1_foreground $mark1_fg
mark1_background $mark1_bg
mark2_foreground $mark2_fg
mark2_background $mark2_bg
mark3_foreground $mark3_fg
mark3_background $mark3_bg

# The basic 16 colors
# black
color0 $black
color8 $bright_black

# red
color1 $red
color9 $bright_red

# green
color2  $green
color10 $bright_green

# yellow
color3  $yellow
color11 $bright_yellow

# blue
color4  $blue
color12 $bright_blue

# magenta
color5  $magenta
color13 $bright_magenta

# cyan
color6  $cyan
color14 $bright_cyan

# white
color7  $white
color15 $bright_white

# You can set the remaining 240 colors as color16 to color255.]]

local helpers = require("lush.transform.helpers")
local check_keys = {
  "fg", "bg",
  "cursor_fg", "cursor_bg",
  "selection_fg", "selection_bg",
  "black", "red", "green", "yellow", "blue",
  "magenta", "cyan", "white",
  "bright_black", "bright_red", "bright_green", "bright_yellow", "bright_blue",
  "bright_magenta", "bright_cyan", "bright_white",
}

local function transform(colors)
  for _, key in ipairs(check_keys) do
    assert(colors[key],
      "kitty colors table missing required key: " .. key)
  end
  local replaced = helpers.split_newlines(helpers.apply_template(template, colors))
  local kept = {}
  for _, line in ipairs(replaced) do
    if not string.match(line, "%$") then
      table.insert(kept, line)
    end
  end

  return kept
end

return transform

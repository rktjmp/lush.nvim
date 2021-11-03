local rgb_convert = require ("lush.vivid.rgb.convert")

--- Replace $values in a string from a table of {values = "string"}
-- "my_color is $COLOR", {COLOR = "red"} -> "my_color is red"
-- @param template A string
-- @param map A table of replacement values
local function apply_template(template, map)
  local output = string.gsub(template, "$([%w%d_]+)", map)
  return output
end

--- Converts a mutli-line string into a table of lines
-- @param text The multi-line string
local function split_newlines(text)
  local lines = {}
  for s in string.gmatch(text, "[^\n]+") do
    table.insert(lines, s)
  end

  return lines
end

local function is_lush_spec(spec)
  if type(spec) == "table" or
    spec.__lush and
    spec.__lush.type == "parsed_lush_spec" then
    return true
  else
    return false
  end
end

return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
  -- split string into table by new lines
  split_newlines = split_newlines,
  -- apply "this is my $template", {template = "replacement"} templating
  apply_template = apply_template,
  -- {r = 255, g = 255, b = 255} -> "0xffffff"
  rgb_to_hex = rgb_convert.rgb_to_hex,
  -- "0xffffff" -> {r = 255, g = 255, b = 255}
  hex_to_rgb = rgb_convert.hex_to_rgb
}

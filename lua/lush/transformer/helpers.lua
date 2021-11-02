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

return {
  split_newlines = split_newlines,
  apply_template = apply_template
}

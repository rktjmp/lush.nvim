-- Head exporter, accepts an AST, returns a table of strings,
--
-- Exports the given theme as a list of rules

local transform = function(ast)
  -- smoke test
  local is_spec = require("shipwright.transform.lush.helpers").is_lush_spec
  assert(is_spec(ast),
    "first argument to lua transform must be a parsed lush spec")

  -- convert ast to table of nvim compatible group defs
  local compiled = require("lush.compiler")(ast)

  -- convert groups+attrs into strings representing the table pairs
  local group_strings = {}
  for group, attrs in pairs(compiled) do
    -- convert each attr into a "key = val" string
    local parts = {}
    for attr, val in pairs(attrs) do
      if type(val) == "string" then
        table.insert(parts, string.format("%s = %q", attr, val))
      elseif type(val) == "number" then
        table.insert(parts, string.format("%s = %s", attr, val))
      elseif type(val) == "boolean" then
        table.insert(parts, string.format("%s = %s", attr, val))
      else
        error(string.format("Unconvertable value type %s for %s.%s", type(val), group, attr))
      end
    end
    table.insert(group_strings, {
      -- concat group name and string'd attrs into "Normal = {fg = ...}"
      definition = string.format("%s = {%s}", group, table.concat(parts, ", ")),
      -- sort each group alphabetically but put link groups directly
      -- after parents.
      sort_key = attrs.link and attrs.link .. "1" .. group or group
    })
  end

  -- apply sort
  table.sort(group_strings, function(a, b)
    return a.sort_key < b.sort_key
  end)

  -- we only want the actual definitions
  local lines = {}
  for _, group in ipairs(group_strings) do
    table.insert(lines, group.definition .. ",")
  end

  return lines
end

return transform

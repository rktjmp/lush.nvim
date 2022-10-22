-- Head exporter, accepts an AST, returns a table of strings,
--
-- Exports the given theme as a list of rules

local function sorted_attr_names(attrs)
  -- we want some specific ordering for our keys when converting them into
  -- strings, both for testing and for DX.
  -- these keys have a fixed best-position, others will be sorted by alpha
  local hardcoded = {
    fg = "1",
    bg = "2",
    sp = "3",
    gui = "4",
    blend = "5"
  }
  local sorted_names = {}
  for attr in pairs(attrs) do
    table.insert(sorted_names, attr)
  end
  table.sort(sorted_names, function(a, b)
    return (hardcoded[a] or a) < (hardcoded[b] or b)
  end)
  return sorted_names
end

local function safe_group_name(name)
  -- any group that has a non-alpha/digit should be wrapped in quotes
  if string.match(name, "[^%a%d]") then
    return string.format("[%q]", name)
  else
    return name
  end
end

return function(ast)
  -- smoke test
  local is_spec = require("shipwright.transform.lush.helpers").is_lush_spec
  local group_sort_value  = require("shipwright.transform.lush.helpers").group_sort_value
  assert(is_spec(ast),
    "first argument to lua transform must be a parsed lush spec")

  -- convert ast to table of nvim compatible group defs
  local compiled = require("lush.compiler")(ast)

  -- convert groups+attrs into strings representing the table pairs
  local group_strings = {}
  for group, attrs in pairs(compiled) do
    -- convert each attr into a "key = val" string
    local parts = {}
    local attr_names = sorted_attr_names(attrs)

    for _, name in ipairs(attr_names) do
      local val = attrs[name]
      if type(val) == "string" then
        table.insert(parts, string.format("%s = %q", name, val))
      elseif type(val) == "number" then
        table.insert(parts, string.format("%s = %s", name, tostring(val)))
      elseif type(val) == "boolean" then
        table.insert(parts, string.format("%s = %s", name, tostring(val)))
      else
        error(string.format("Unconvertable value type %s for %s.%s", type(val), group, name))
      end
    end
    table.insert(group_strings, {
      -- concat group name and string'd attrs into "Normal = {fg = ...}"
      definition = string.format(
        "%s = {%s}",
        safe_group_name(group),
        table.concat(parts, ", ")
      ),
      -- sort each group alphabetically but put link groups directly
      -- after parents.
      sort_key = group_sort_value(group, attrs)
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

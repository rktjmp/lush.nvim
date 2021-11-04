--- Head exporter, accepts an AST, returns a table of strings, each
--- corresponding to a highlight rule.
--
-- @param config config to pass to lush.compile
local compiler = require("lush.compiler")
local is_spec = require("shipwright.transform.lush.helpers").is_lush_spec

local sort_value = function(rule)
  local link_from, link_to = string.match(rule, "link%s+([%w_]+)%s+([%w_]+)")
  local group_name = string.match(rule, "highlight%s+([%w_]+)")
  if group_name then
    -- groups just sort by name
    return group_name
  else
    -- links sort primarily by their target, then by their own name
    return link_to .. "1" .. link_from
  end
end

return function(ast, config)
  assert(is_spec(ast),
    "first argument to vimscript transform must be a parsed lush spec")

  local rules = compiler(ast, config)

  -- sort the rules aphabetically  so diffs are consistenly ordered.
  -- We will sort primarily by group name, but sort links to be just
  -- after their target
  -- https://github.com/savq/melange/pull/32#issuecomment-960247099
  table.sort(rules, function(a, b)
    return sort_value(a) < sort_value(b)
  end)

  return rules
end

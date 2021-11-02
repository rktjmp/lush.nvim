-- Head exporter, accepts an AST, returns a table of strings, each
-- corresponding to a highlight rule.
local compiler = require("lush.compiler")
local is_spec = require("lush.transform.helpers").is_lush_spec

return function(ast, config)
  assert(is_spec(ast),
    "first argument to viml transform must be a parsed lush spec")

  return compiler(ast, config)
end

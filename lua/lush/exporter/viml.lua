-- Head exporter, accepts an AST, returns a table of strings, each
-- corresponding to a highlight rule.
local compiler = require("lush.compiler")

return function(ast, config)
  -- we always enforce force_clean = false?
  -- maybe not...
  compiler(ast, config)
end

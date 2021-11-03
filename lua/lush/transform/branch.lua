--- Accepts a value and a pipeline, runs the value through the pipeline but
--- returns the original value
local run = require("lush.builder").run
return function(value, ...)
  -- run the given pipe line
  run(value, ...)
  -- but return the first value
  return value
end

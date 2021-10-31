-- Exporter core
--
-- export accepts a lush module name to load, and any number of functions to chain
-- through as transformations. You must provide at least one function.
--
-- The first fuction *must* accept a lush spec AST (from the given lush module).
-- Every other function should accept and return a table.

local function export(lush_module, ...)
  local pipeline = {...}
  assert(#pipeline > 0,
    lush_module .. " export pipeline must have at least one function!")
  assert(type(lush_module) == "string",
    "first export argument must be a string, got " .. vim.inspect(lush_module))

  -- we always start with the ast
  local value = require(lush_module)

  -- pass through the pipeline
  for i, transform in ipairs(pipeline) do
    if type(transform) == "function" then
      -- raw function, just value -> value
      value = transform(value)
    elseif type(transform) == "table" then
      -- table, first element must be the transformer, the rest are assumed to
      -- be arguments for the transformer, excepting that the *first* argument
      -- should be the current value.
      assert(#transform > 0, lush_module .. " transformation # " .. i .. " was table with length 0")
      -- slice copies the table, we want to be non-destructive (no table.remove to shift)
      -- because the config may be shared between other export calls
      local func = transform[1]
      local args = vim.list_slice(transform, 2, #transform)
      value = func(value, unpack(args))
    end

    assert(type(value) == "table",
      lush_module .. " transformation #" .. i .. " did not return a table")
  end

  -- We will return the value, mostly for debugging purposes.
  -- It's expected that one of the transformations has done something
  -- useful with the work in terms of writing to disk or loading into memory.
  return value
end

return export

-- Exporter core
--
-- export accepts a lush module name to load, and any number of functions to
-- chain through as transformations. You must provide at least one function.
--
-- The first fuction *must* accept a lush spec AST (from the given lush
-- module). Every other function should accept and return a table.

local function is_spec(spec)
  if type(spec) == "table" or
    spec.__lush and
    spec.__lush.type == "parsed_lush_spec" then
    return true
  else
    return false
  end
end

local function export(parsed_lush_spec, ...)
  -- we always start with the ast
  local value = parsed_lush_spec
  local continue_pipeline = nil -- anything but false will continue
  local pipeline = {...}

  assert(is_spec(value),
    "first argument to export must be a parsed lush spec")
  assert(#pipeline > 0,
    "export pipeline must have at least one function!")

  -- pass through the pipeline
  for i, transform in ipairs(pipeline) do
    if type(transform) == "function" then
      -- raw function, just value -> value
      value, continue_pipeline = transform(value)
    elseif type(transform) == "table" then
      -- table, first element must be the transformer, the rest are assumed to
      -- be arguments for the transformer, excepting that the *first* argument
      -- should be the current value.
      assert(#transform > 0,
        " transformation # " .. i .. " was table with length 0")
      -- slice copies the table, we want to be non-destructive (no table.remove
      -- to shift) because the config may be shared between other export calls
      local func = transform[1]
      local args = vim.list_slice(transform, 2, #transform)
      value, continue_pipeline = func(value, unpack(args))
    end

    assert(type(value) == "table",
      " transformation #" .. i .. " did not return a table")

    if continue_pipeline == false then break end
  end

  -- We will return the value, mostly for debugging purposes.
  -- It's expected that one of the transformations has done something
  -- useful with the work in terms of writing to disk or loading into memory.
  return value
end

-- Create an environment to run the build file in. This should expose all the
-- built in transformers, as well as lush itself.
local function make_env()
  local env = {
    lush = require("lush"),
    export = require("lush.exporter").export,
    viml = require("lush.transformer.viml"),
    overwrite = require("lush.transformer.overwrite"),
    patchwrite = require("lush.transformer.patchwrite"),
    prepend_lines = require("lush.transformer.prepend_lines"),
    append_lines = require("lush.transformer.append_lines"),
  }
  return setmetatable(env, {
    __index = function(_, name)
      -- proxy out to the real env when needed
      return _G[name]
    end
  })
end

return {
  export = export,
  make_env = make_env
}

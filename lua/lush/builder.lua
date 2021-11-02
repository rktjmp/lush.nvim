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

local function run_pipeline(parsed_lush_spec, ...)
  -- we always start with the ast
  local value = parsed_lush_spec
  local continue_pipeline = nil -- anything but false will continue
  local pipeline = {...}

  assert(is_spec(value),
    "first argument to export must be a parsed lush spec")
  -- because lua tables are garbage, you can do something like
  -- {my_pip, my_pipe, my_pipe} and get {nil, fn, fn},
  -- (and my_pip wont error, just silently nil out)
  -- #pipeline = 3, but ipairs wont iterate at all because it hits a nil
  -- so we will actually check that the pipeline has content we can iterate.
  local check_count = 0
  for _, _ in ipairs(pipeline) do
    check_count = check_count + 1
  end
  assert(#pipeline == check_count,
    "export pipeline reported length and actual length differ, you probably have a nil in it (mis-spelling?)")

  -- pass through the pipeline
  for i, transform in ipairs(pipeline) do
    if type(transform) == "function" then
      -- raw function, just value -> value
      value, continue_pipeline = transform(value)
    elseif type(transform) == "table" then
      -- table, first element must be the transform, the rest are assumed to
      -- be arguments for the transform, excepting that the *first* argument
      -- should be the current value.
      assert(#transform > 0,
        " transformation # " .. i .. " was table with length 0")
      -- slice copies the table, we want to be non-destructive (no table.remove
      -- to shift) because the config may be shared between other export calls
      local func = transform[1]
      assert(func,
       "given transform function was nil, did you mis-spell it?")
      local args = vim.list_slice(transform, 2, #transform)
      value, continue_pipeline = func(value, unpack(args))
    else
      error("Invalid type in pipeline at index " .. i .. " ( " .. type(transform) .. ")")
    end

    assert(type(value) == "table",
      " transformation #" .. i .. " did not return a table")

    if continue_pipeline == false then break end
  end

  return value
end

-- Create an environment to run the build file in.
-- This should expose all the built in transformers, as well as lush itself.
local function make_env()
  local env = {
    lush = require("lush"),
    transform = require("lush.builder").transform,
    viml = require("lush.transform.viml"),
    lua = require("lush.transform.lua"),
    overwrite = require("lush.transform.overwrite"),
    patchwrite = require("lush.transform.patchwrite"),
    prepend = require("lush.transform.prepend"),
    append = require("lush.transform.append"),
    contrib = {
      alacritty = require("lush.transform.contrib.alacritty"),
      wezterm = require("lush.transform.contrib.wezterm"),
      kitty = require("lush.transform.contrib.kitty"),
    }
  }
  return setmetatable(env, {
    __index = function(_, name)
      -- proxy out to the real env when needed
      return _G[name]
    end
  })
end

return {
  transform = run_pipeline,
  make_env = make_env
}

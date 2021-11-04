local hsl = require('lush.vivid.hsl.type')
local hsluv = require('lush.vivid.hsluv.type')

local parser = require('lush.parser')
local compiler = require('lush.compiler')

local function merge_default_options(options)
  if not options then
    options = {
      -- default to clean
      force_clean = true
    }
  end
  return options
end

local insert_force_clean = function(compiled_ast)
    local clean = {
      "hi clear",
      "set t_Co=256",
    }
    if vim.g.colors_name then
      -- 'hi clear' will clear g:colors_name, so restore if it existed
      table.insert(clean, "let g:colors_name='" .. vim.g.colors_name.."'")
    end

    for i, c in ipairs(clean) do
      table.insert(compiled_ast, i, c)
    end

    return compiled_ast
end

local M = {}

-- usability binds
M.hsl = hsl
M.hsluv = hsluv
M.ify = function(options)
  -- localise this require so test's don't complain about
  -- missing vim globals, etc
  require('lush.ify')(options)
end

-- spec -> table
M.parse = function(spec, options)
  return parser(spec, options)
end

-- table -> table
M.compile = function(ast, options)
  local compiled = compiler(ast, options)

  if options and options.force_clean then
    compiled = insert_force_clean(compiled)
  end

  return compiled
end

-- accepts list of highlight commands from compile() to apply
M.apply = function(compiled)
  for _, cmd in ipairs(compiled) do
    vim.api.nvim_command(cmd)
  end
end

M.stringify = function(parsed_spec, options)
  options = merge_default_options(options)
  local compiled = M.compile(parsed_spec, options)
  return table.concat(compiled, '\n')
end

M.export_to_buffer = function(parsed_spec)
  local lines = M.compile(parsed_spec)

  table.insert(lines, 1, "\"Theme built with Lush.nvim, exported at " .. os.date())

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = vim.api.nvim_win_get_width(0) - 2 ,
    height = vim.api.nvim_win_get_height(0) - 2,
    row = 1,
    col = 1,
    style = "minimal",
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

M.import = function()
  local importer = require("lush.importer")
  return importer.import()
end

-- given a spec function, generate a parsed spec
-- (spec, table) -> table
local easy_spec = function(spec, options)
  local parsed = M.parse(spec, options)
  -- return parsed spec for use with externals
  return parsed
end

-- given a parsed spec, apply the spec
local easy_parsed = function(parsed_spec, options)
  options = merge_default_options(options)

  local compiled = M.compile(parsed_spec, options)
  -- run automatically
  M.apply(compiled)

  -- return parsed spec for use with externals
  -- TODO: Should easy_parsed return parsed_spec or a different identifier?
  return parsed_spec
end

-- We can call lush in two styles, with the intention of making boilerplate
-- easier. detect_easy is metaprogramed to M.__call.
--
-- lush(function() ... end)
--   -> define a lush spec, returns a parsed spec
--   -> traditionally called in a lua/lush_theme/theme.lua file
--
-- lush({...})
--   -> applying a parsed spec, automatically sets the clear option
--   -> traditionally called in the colors/colors.vim file
--
-- (spec or parsed_spec, table) -> parsed_spec or apply_spec
local function detect_easy(spec_or_parsed, options)
  -- specs are functions
  if type(spec_or_parsed) == "function" then
    local spec = spec_or_parsed
    return easy_spec(spec, options)
  -- parsed specs are tables
  elseif type(spec_or_parsed) == "table" and
         spec_or_parsed.__lush and
         spec_or_parsed.__lush.type == "parsed_lush_spec" then
    local parsed = spec_or_parsed
    return easy_parsed(parsed, options)
  else
    error("lush() supplied incorrect arguments")
  end
end

-- accepts list of parsed specs which it passes to the 'with'd specs
-- under the extends option
-- returns a parsed_lush_spec
M.extends = function(extends_list)
  local with = function(spec, options)
    options = options or {}
    options.extends = extends_list
    return M.parse(spec, options)
  end

  return {
    with = with
  }
end

-- accepts a list of parsed specs, merges them in order
-- (equivilent to extends({...}).with(empty_spec))
-- returns a parsed_lush_spec
M.merge = function(extends_list)
  local options = {
    extends = extends_list
  }

  local empty_spec = function()
    return {}
  end

  return M.parse(empty_spec, options)
end

-- delegate __call to detect_easy for DX QOL.
return setmetatable(M, {
  __call = function(m, ...)
    local fn, opts = ...
    return detect_easy(fn, opts)
  end,
})

local hsl = require('lush.hsl')
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
      "syntax reset",
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
M.ify = function()
  -- localise this require so test's don't complain about
  -- missing vim globals, etc
  require('lush.ify')()
end

-- spec -> table
M.parse = function(spec, options)
  return parser(spec)
end

-- table -> table
M.compile = function(ast, options)
  local compiled = compiler(ast)

  if options and options.force_clean then
    compiled = insert_force_clean(compiled)
  end

  return compiled
end

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

  table.insert(lines, 1, "\" Lush.nvim theme exported at " .. os.date())

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

-- (spec, table) -> table
local easy = function(spec, options)
  options = merge_default_options(options)

  local parsed = M.parse(spec, options)
  local compiled = M.compile(parsed, options)
  -- run automatically
  M.apply(compiled)

  -- return parsed spec for use with externals
  return parsed
end


return setmetatable(M, {
  __call = function(m, ...)
    local fn, opts = ...
    return easy(fn, opts)
  end
})

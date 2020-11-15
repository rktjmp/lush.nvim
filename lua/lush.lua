local hsl = require('lush.hsl')
local parser = require('lush.parser')
local compiler = require('lush.compiler')

local M = {}

M.hsl = hsl

M.ify = function()
  -- localise this require so test's don't complain about
  -- missing vim globals, etc
  require('lush.ify')()
end

M.create = function(fn, options)
  local compiled = compiler(parser(fn))
  if options and options.force_clean then
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
      table.insert(compiled, i, c)
    end
  end
  return compiled
end

M.apply = function(scheme)
  for _, cmd in ipairs(scheme) do
    vim.api.nvim_command(cmd)
  end
end

M.stringify = function(scheme)
  return table.concat(scheme, '\n') .. "\n"
end

return setmetatable(M, {
  __call = function(m, ...)
    local fn, opts = ...
    m.apply(M.create(fn, opts))
  end
})

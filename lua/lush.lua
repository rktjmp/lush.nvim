local hsl = require('lush.hsl')
local parser = require('lush.parser')
local compiler = require('lush.compiler')
local ify = require('lush.ify')

local M = {}

M.ify = ify
M.hsl = hsl

M.define = function(fn)
  local compiled = compiler(parser(fn))
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
  __call = function(m, fn)
    m.apply(M.define(fn))
  end
})

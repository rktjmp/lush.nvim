-- middle transformer, prepends given lines to input

return function(lines, before)
  assert(type(before) == "table",
    "append transformer requires table as argument")

  -- build fresh cause mutability sucks
  local build = {}
  for _, line in ipairs(before) do
    table.insert(build, line)
  end
  for _, line in ipairs(lines) do
    table.insert(build, line)
  end

  return build
end

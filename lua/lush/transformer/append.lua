-- middle transformer, appends given elements to input

return function(before, after)
  assert(type(after) == "table",
    "append transformer requires table as argument")

  -- build fresh cause mutability sucks
  local build = {}
  for _, line in ipairs(before) do
    table.insert(build, line)
  end
  for _, line in ipairs(after) do
    table.insert(build, line)
  end

  return build
end

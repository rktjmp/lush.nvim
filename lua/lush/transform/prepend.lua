--- Prepends given argument to input table
-- @param after table to prepend to
-- @param before either a single item to prepend or a table of items to prepend
return function(after, before)
  -- build fresh cause mutability sucks
  local collect = {}

  if type(after) == table then
    for _, line in ipairs(before) do
      table.insert(collect, line)
    end
  else
    table.insert(collect, before)
  end

  for _, line in ipairs(after) do
    table.insert(collect, line)
  end

  return collect
end

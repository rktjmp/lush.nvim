--- Appends given argument to input table
-- @param before table to append to
-- @param after either a single item to append or a table of items to append
return function(before, after)
  -- build fresh cause mutability sucks
  local collect = {}

  for _, line in ipairs(before) do
    table.insert(collect, line)
  end

  if type(after) == table then
    for _, line in ipairs(after) do
      table.insert(collect, line)
    end
  else
    table.insert(collect, after)
  end

  return collect
end

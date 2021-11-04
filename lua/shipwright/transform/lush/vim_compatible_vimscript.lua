--- Alters a list of vim script highlight commands to be vim compatible
return function(rules)
  local collect = {}
  for _, rule in ipairs(rules) do
    -- vim cant handle blend values
    -- be hygenic
    local clone = rule
    clone = string.gsub(clone, " blend=NONE", "")
    clone = string.gsub(clone, " blend=%d+", "")

    local gui = string.match(clone, "gui=([%w,]+)")
    if gui then
      -- link rules wont have a gui field
      clone = clone .. " cterm=" .. gui
    end

    table.insert(collect, clone)
  end

  return collect
end

local function is_lush_spec(spec)
  if type(spec) == "table" or
    spec.__lush and
    spec.__lush.type == "parsed_lush_spec" then
    return true
  else
    return false
  end
end

local sort_value = function(group, attrs)
  -- Normal group must appear first as other groups may implicity use its
  -- values via fg = "bg"
  local normal_special = "000Normal"
  if attrs.link then
    if attrs.link == "Normal" then
      return normal_special .. "1" .. group
    else
      return attrs.link .. "1" .. group
    end
  else
    if group == "Normal" then
      return normal_special
    else
      return group
    end
  end
end


return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
  group_sort_value = sort_value
}

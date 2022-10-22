local function is_lush_spec(spec)
  if type(spec) == "table" or
    spec.__lush and
    spec.__lush.type == "parsed_lush_spec" then
    return true
  else
    return false
  end
end

local sortable_name = function(name)
  -- we want to strip quotes in group names and also shuffle
  -- punctutation prefixed names to the bottom.
  local unquoted = string.gsub(name, "['\"]", "")
  return string.gsub(unquoted, "^[%p]+", "zzzz")
end

local sort_value = function(group, attrs)
  -- Normal group must appear first as other groups may implicity use its
  -- values via fg = "bg"
  local normal_special = "000Normal"

  if attrs.link then
    if attrs.link == "Normal" then
      return normal_special .. "1" .. sortable_name(group)
    else
      return sortable_name(attrs.link) .. "1" .. sortable_name(group)
    end
  else
    if group == "Normal" then
      return normal_special
    else
      return sortable_name(group)
    end
  end
end


return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
  group_sort_value = sort_value
}

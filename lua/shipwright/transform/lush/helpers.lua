local function is_lush_spec(spec)
  if type(spec) == "table" or
    spec.__lush and
    spec.__lush.type == "parsed_lush_spec" then
    return true
  else
    return false
  end
end


return {
  -- is argument a lush spec
  is_lush_spec = is_lush_spec,
}

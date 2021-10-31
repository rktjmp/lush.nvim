-- remove spaces from string (invalid in rules except as separator)
local function strip_spaces(str)
  return string.gsub(str, ' ', '')
end

-- sanitise value if empty or blank
local function value_or_NONE(value)
  if value == nil or value == '' then
    return 'NONE'
  end

  return strip_spaces(tostring(value))
end

return {
  value_or_NONE = value_or_NONE
}

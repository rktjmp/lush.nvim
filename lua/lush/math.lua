
local clamp = function(val, min, max)
  return math.min(max, math.max(min, val))
end

-- round float, implementation rounds 0.5 upwards.
local round = function(val)
  return math.floor(val + 0.5)
end

return {
  round = round,
  clamp = clamp
}

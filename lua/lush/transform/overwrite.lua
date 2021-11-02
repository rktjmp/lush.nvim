-- Tail exporter, accepts a table of strings and a path

return function(lines, path)
  assert(path, "overwrite requires a path")

  local fd, e = io.open(path, "w")
  assert(fd, e)

  for _, line in ipairs(lines) do
    fd:write(line .. "\n")
  end

  fd:close()

  return lines
end

-- Tail exporter, accepts a table of strings and a path

return function(lines, path, config)
  print("overwrite " .. path .. " with " .. #lines .. " lines")
end

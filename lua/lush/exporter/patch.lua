-- Tail exporter, accepts a table of strings and a path
--
-- This exporter will patch the existing path, accepts a configurable
-- open and close marker.

return function(lines, path, config)
  print("patch " .. path .. " with " .. #lines .. " lines")
end

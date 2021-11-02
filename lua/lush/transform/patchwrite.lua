-- Tail exporter, accepts a table of strings and a path
--
-- This exporter will patch the existing path between the patch open and close
-- markers.
return function(lines, path, patch_open, patch_close)
  assert(path, "patchwrite requires a path")
  assert(patch_open, "patchwrite requires a patch open string")
  assert(patch_close, "patchwrite requires a patch close string")

  local fd, e = io.open(path, "r")
  assert(fd, e)

  local mode = "pre-copy" -- or skip when inside patch
  local pre_content = {}
  local post_content = {}
  local saw_marker = false

  -- get lines until we match the marker
  for line in fd:lines() do
    if string.match(line, patch_open) then
      -- copy the marker line
      table.insert(pre_content, line)
      mode = "skip"
      saw_marker = true
    elseif string.match(line, patch_close) then
      mode = "post-copy"
      -- marker line will be copied in the if
    end
    if mode == "pre-copy" then
      table.insert(pre_content, line)
    elseif mode == "post-copy" then
      table.insert(post_content, line)
    end
  end
  fd:close()

  -- we may or may not want to guard against this
  assert(#pre_content > 0,
    "patchwrite failed for " .. path .. ", found no content before marker")
  assert(#post_content > 0,
    "patchwrite failed for " .. path .. ", found no content after marker")
  assert(saw_marker,
    "patchwrite never saw patch markers: " .. patch_open .. " & " .. patch_close)

  fd, e = io.open(path, "w")
  assert(fd, e)
  for _, line in ipairs(pre_content) do
    fd:write(line .. "\n")
  end
  for _, line in ipairs(lines) do
    fd:write(line .. "\n")
  end
  for _, line in ipairs(post_content) do
    fd:write(line .. "\n")
  end
  fd:close()

  return lines
end

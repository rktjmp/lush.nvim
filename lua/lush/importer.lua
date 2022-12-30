local group_pattern = "[@.%w_]+"

local function format_group_name(group_name)
  if (string.match(group_name, "[@.]")) then
    return 'sym"' .. group_name .. '"'
  end
  return group_name
end

local function extract_link_group(line)
  -- StatusLineFileInfo xxx links to StatusLine
  local from, to = string.match(line, "(" .. group_pattern .. ")%s+xxx%s+links to%s+(" .. group_pattern .. ")")
  return {
    from = format_group_name(from),
    to = format_group_name(to),
    comment = line
  }
end

local function extract_direct_group(line)
  -- LspDiagnosticsSignError xxx guifg=#CC4B52 guibg=#212520
  -- LspDiagnosticsSignWarning xxx cleared
  local group_name, rules = string.match(line, "(" .. group_pattern .. ")%s+xxx%s+(%w.+)")
  -- we explicitly support the following rules:
  -- guifg -> fg
  -- guibg -> bg
  -- guisp -> sp
  -- gui -> gui
  -- blend -> blend
  -- color values can be #F0FA12 or #f0fa12 or red
  local attrs = {
    fg = string.match(rules, "guifg=([%w#]+)"),
    bg = string.match(rules, "guibg=([%w#]+)"),
    sp = string.match(rules, "guisp=([%w#]+)"),
    gui = string.match(rules, "gui=([%w,]+)"),
    blend = string.match(rules, "blend=([%d]+)"),
  }
  return {format_group_name(group_name), attrs, line}
end

local function direct_to_string(group_name, attrs, rules, pad_to)
  local name = group_name .. string.rep(" ", pad_to - string.len(group_name))
  local str = ""
  str = str .. name .. " { "
  for key, val in pairs(attrs) do
    -- blend should not have quotes around it
    local wrapped = key == "blend" and val or "\"" .. val .. "\""
    str = str .. key .. "=" .. string.lower(wrapped) .. ", "
  end
  str = str .. "}, -- " .. rules
  return str
end

local function link_to_string(group, pad_to)
  local name = group.from .. string.rep(" ", pad_to - string.len(group.from))
  return string.format("%s { %s }, -- %s", name, group.to, group.comment)
end

local function capture_current()
  -- StatusLineGitInfoSep xxx guifg=#1D201C
  -- LspDiagnosticsSignWarning xxx guifg=#F5C562 gu
  local direct_groups = {}
  local link_groups = {}

  local lines = {}
  for line in string.gmatch(vim.fn.execute("highlight"), "[^\n]+") do
    -- https://github.com/rktjmp/lush.nvim/issues/106
    -- https://github.com/rktjmp/lush.nvim/issues/94
    if not string.match(line, "nvim_set_hl_x_hi_clear_bugfix") then
      table.insert(lines, line)
    end
  end

  for i, s in ipairs(lines) do
    -- links to can be a raw link or actually a link to the previously seen line
    -- DiagnosticSignError xxx links to LspDiagnosticsSignError
    -- DiagnosticUnderlineError xxx cterm=underline guisp=Red
    --                    links to LspDiagnosticsUnderlineError
    if string.match(s, group_pattern .. "%s+links to") then
      table.insert(link_groups, extract_link_group(s))
    elseif string.match(s, "%s+links to") then
      -- lua will still match the link regex, from will just be nil
      local linkish = extract_link_group(s)
      -- but we can get the from, from the previous line's group
      local group = extract_direct_group(lines[i-1])
      -- patch and insert
      linkish.from = group[1]
      table.insert(link_groups, linkish)
    elseif string.match(s, "%scleared") then
      -- should be ok to skip "cleared" groups as hl clear will cover them
    elseif string.match(s, group_pattern .. "%s+xxx%s+.+") then
      table.insert(direct_groups, extract_direct_group(s))
    else
      print("no match:" .. s)
    end
  end

  -- grab some formatting data
  local max_name_width = 0
  for _, group in ipairs(direct_groups) do
    local name = unpack(group)
    local len = string.len(name)
    max_name_width = (len > max_name_width and len) or max_name_width
  end
  for _, link in ipairs(link_groups) do
    if link.from == nil then
      print(vim.inspect(link))
    end
  end
  for _, link in ipairs(link_groups) do
    local name = link.from
    local len = string.len(name)
    max_name_width = (len > max_name_width and len) or max_name_width
  end

  local collect = {}
  for _, group in ipairs(direct_groups) do
    local name, attrs, comment = unpack(group)
    table.insert(collect, "    " .. direct_to_string(name, attrs, comment, max_name_width))
    -- any links to this group should be output after it
    for _, link in ipairs(link_groups) do
      if link.to == name then
        table.insert(collect, "    " .. link_to_string(link, max_name_width))
      end
    end
  end

  -- insert some wrapping context
  table.insert(collect, 1, "  return {")
  table.insert(collect, 1, "  local sym = injected_functions.sym")
  table.insert(collect, 1, "local theme = lush(function(injected_functions)")
  table.insert(collect, 1, "local hsluv = lush.hsluv")
  table.insert(collect, 1, "local hsl = lush.hsl")
  table.insert(collect, 1, "local lush = require(\"lush\")")
  table.insert(collect, 1, "-- then /Normal to find the Normal group and edit your fg & bg colors")
  table.insert(collect, 1, "-- Run :Lushify")
  table.insert(collect, 1, "-- autogenerated lush spec on " .. os.date())
  table.insert(collect, "  }")
  table.insert(collect, "end)")
  table.insert(collect, "return theme")

  -- print(vim.inspect(collect))
  vim.fn.setreg("z", table.concat(collect, "\n"))
  print("Saved current theme to 'z' register, use \"zp to paste into new file and run :Lushify (you might also want to run `:set ft=lua nowrap`)")
end

return capture_current

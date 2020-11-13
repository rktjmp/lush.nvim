
-- TODO: args such as default, etc
-- TODO: include !?
local function make_link(from, to)
  return "highlight! link " .. from .. " " .. to
end

local function make_group(name, opts)
  -- We define groups "greedily", meaning we set any un-set options to NONE
  -- TODO: good idea or nah?
  return table.concat({
    'highlight ' .. name,
    'guifg=' .. (opts.fg or 'NONE'),
    'guibg=' .. (opts.bg or 'NONE'),
    'guisp=' .. (opts.sp or 'NONE'),
    'gui=' .. (opts.gui or 'NONE'),
  }, ' ')
end

local function compile(ast)
  local commands = {}
  for group_name, group_def in pairs(ast) do
    if group_def.link then
      table.insert(commands, make_link(group_name, group_def.link))
    else
      table.insert(commands, make_group(group_name, group_def))
    end
  end

  return commands
end

return compile

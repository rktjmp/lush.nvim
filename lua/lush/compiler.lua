
-- TODO: args such as default, etc
-- TODO: include !?
local function make_link(from, to)
  return "highlight! link " .. from .. " " .. to
end

local function make_group(name, opts)
  -- We define groups "greedily", meaning we set any un-set options to NONE
  -- TODO: good idea or nah?
  -- 2021/02/19 - believe it was chosen because it allowed for {} group defs
  --              which can clear exiting highlights

  -- be nice and fix gui spaces if present
  local gui = opts.gui or 'NONE'
  gui = string.gsub(gui, ' ', '')

  return table.concat({
    'highlight ' .. name,
    'guifg=' .. (opts.fg or 'NONE'),
    'guibg=' .. (opts.bg or 'NONE'),
    'guisp=' .. (opts.sp or 'NONE'),
    'gui=' .. gui,
    'blend=' .. (opts.blend or 'NONE'),
  }, ' ')
end

local function compile(ast)
  assert(type(ast) == "table" and ast.__type == "parsed_lush_spec",
         "can't compile, incorrect argument type", 4)
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

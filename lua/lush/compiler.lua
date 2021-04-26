
-- TODO: args such as default, etc
-- TODO: include !?
local function make_link(from, to)
  return "highlight! link " .. from .. " " .. to
end

local function value_or_NONE(value)
  if value == nil or value == '' then
    return 'NONE'
  end

  return value
end

local function make_group(name, opts)
  -- We define groups "greedily", meaning we set any un-set options to NONE
  -- TODO: good idea or nah?
  -- 2021/02/19 - believe it was chosen because it allowed for {} group defs
  --              which can clear exiting highlights

  -- be nice and fix gui spaces if present
  local gui = value_or_NONE(opts.gui)
  gui = string.gsub(gui, ' ', '')

  return table.concat({
    'highlight ' .. name,
    'guifg=' .. value_or_NONE(opts.fg),
    'guibg=' .. value_or_NONE(opts.bg),
    'guisp=' .. value_or_NONE(opts.sp),
    'gui=' .. value_or_NONE(gui),
    'blend=' .. value_or_NONE(opts.blend),
  }, ' ')
end

local function compile(ast)
  assert(type(ast) == "table" and ast.__lush.type == "parsed_lush_spec",
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

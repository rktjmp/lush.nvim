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

-- check if value is_in list
local function is_in(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

-- make sure options is usable
local function normalise_options(options)
  if options == nil then options = {} end
  if options.exclude_keys == nil then options.exclude_keys = {} end
  return options
end

-- creates a link group
local function make_link(from, to, _)
  return "highlight! link " .. from .. " " .. to
end


local function make_group(name, values, options)
  -- We define groups "greedily", meaning we set any un-set options to NONE
  -- This allows for Group {} to actually clear highlighting, which was
  -- personally preferable to me who uses very few highlights.

  -- filter the keys we will get thorugh the exclude_keys list
  local accepted = {}
  for _, key in ipairs({"fg", "bg", "sp", "gui", "blend"}) do
    if not is_in(options.exclude_keys, key) then
      table.insert(accepted, key)
    end
  end

  -- map between lush keys and vim keys
  local translator = {
    fg = "guifg",
    bg = "guibg",
    sp = "guisp",
    gui = "gui",
    blend = "blend"
  }

  -- pair lush keys to vim keys
  local builder = {}
  for _, key in ipairs(accepted) do
    table.insert(builder, translator[key] .. "=" .. value_or_NONE(values[key]))
  end

  if #builder == 0 then
    return ""
  else
    table.insert(builder, 1, "highlight " .. name)
    return table.concat(builder, ' ')
  end
end

local function compile(ast, options)
  assert(type(ast) == "table" and ast.__lush.type == "parsed_lush_spec",
         "can't compile, incorrect argument type", 4)
  local commands = {}
  options = normalise_options(options)

  for group_name, group_def in pairs(ast) do
    local command
    if group_def.link then
      command = make_link(group_name, group_def.link, options)
    else
      command = make_group(group_name, group_def, options)
    end
    if command ~= "" then
      table.insert(commands, command)
    end
  end

  return commands
end

return compile

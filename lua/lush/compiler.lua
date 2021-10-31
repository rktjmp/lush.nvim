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
  if options.plugins == nil then options.plugins = {} end
  return options
end



local function compile(ast, options)
  assert(type(ast) == "table" and ast.__lush.type == "parsed_lush_spec",
         "can't compile, incorrect argument type", 4)
         
  local commands = {}
  options = normalise_options(options)

  -- we always start with the lush_core plugin, then progressively pass through
  -- the options.plugins table
  local plugins = {
    require("lush.compiler_plugins.lush_core"),
  }
  for _, plug in ipairs(options.plugins) do
    table.insert(plugins, plug)
  end

  for group_name, group_def in pairs(ast) do
    local command = ""
    local maybe_halt = nil

    if group_def.link then
      for _, plug in ipairs(plugins) do
        command, maybe_halt = plug.make_link(group_name, group_def.link, command, ast)
        assert(type(command) == "string",
          "compiler plugin " .. plug.name
            .. " did not return string for make_link " .. group_name)
        if maybe_halt == true then break end
      end
    else
      for _, plug in ipairs(plugins) do
        command, maybe_halt = plug.make_group(group_name, group_def, command, ast)
        assert(type(command) == "string",
          "compiler plugin " .. plug.name
            .. " did not return string for make_group " .. group_name)
        if maybe_halt == true then break end
      end
    end

    if command ~= "" then
      table.insert(commands, command)
    end
  end

  return commands
end

return compile

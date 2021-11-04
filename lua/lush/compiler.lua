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
    require("lush.compiler.plugin.lush_core"),
  }

  -- TODO deprecated, remove 1/12
  if options.exclude_keys then
    print("Warning: exclude_keys is deprecated, please see BUILD.md")
  end

  for _, plug in ipairs(options.plugins) do
    table.insert(plugins, plug)
  end

  for group_name, group_def in pairs(ast) do
    local command = ""
    local continue_pipeline = nil -- anything but false will continue

    for _, plug in ipairs(plugins) do
      if group_def.link then
        command, continue_pipeline = plug.make_link(group_name,
                                                    group_def.link,
                                                    command,
                                                    ast)
        assert(type(command) == "string",
          "compiler plugin " .. plug.name
            .. " did not return string for make_link " .. group_name)
      else
        command, continue_pipeline = plug.make_group(group_name,
                                                     group_def,
                                                     command,
                                                     ast,
                                                     -- deprecated, remove 1/12
                                                     options.exclude_keys)
        assert(type(command) == "string",
          "compiler plugin " .. plug.name
            .. " did not return string for make_group " .. group_name)
      end
      if continue_pipeline == false then break end
    end

    if command ~= "" then
      table.insert(commands, command)
    end
  end

  return commands
end

return compile

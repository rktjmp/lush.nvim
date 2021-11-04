local value_or_NONE = require("lush.compiler.plugin.utils").value_or_NONE

local lush_core = {
  -- used for error reporting, you should provide a nice name
  name = "lush_core",

  -- Called when a regular group is encountered.
  --
  -- I.e: `LuaStatement { fg = ... }`
  --
  -- `group_name` is the current group we're operating on (`LuaStatement`).
  -- `group_spec` is the table representing the group with keys such as "fg",
  --              "bg", etc *if* they are present in the theme. These values may
  --              be hsl()/etc types OR strings, depending on what was used at theme
  --              construction.
  -- `current_rule` is the string result of plugins before this.
  -- `entire_spec` is the entire parsed lush spec for introspection.
  --
  -- Should return the highlight rule as a string, and optionally false to
  -- prevent any future plugins from executing.
  --
  -- I.e: `return "highlight! LuaStatement fg=red"` will set the
  -- highlight rule which will be passed to the next plugin in the chain (if it
  -- exists).
  --
  -- I.e: `return "highlight! LuaStatement fg=red", false` will set the
  -- highlight rule and prevent any other plugins from running.
  make_group = function(group_name, group_spec, current_rule, entire_spec, exclude_keys)
    -- We define groups "greedily", meaning we set any un-set options to NONE
    -- This allows for Group {} to actually clear highlighting, which was
    -- personally preferable to me who uses very few highlights.

    -- map between lush keys and vim keys
    local translator = {
      fg = "guifg",
      bg = "guibg",
      sp = "guisp",
      gui = "gui",
      blend = "blend"
    }

    -- TODO deprecated, remove 1/12
    local keys = {"fg", "bg", "sp", "gui", "blend"}
    if exclude_keys then
      -- check if value is_in list
      local function contains(list, value)
        for _, v in ipairs(list) do
          if v == value then return true end
        end
        return false
      end
      local filtered = {}
      for _, key in ipairs(keys) do
        if not contains(exclude_keys, key) then
          table.insert(filtered, key)
        end
      end
       keys = filtered
    end

    -- pair lush keys to vim keys
    local builder = {}

    for _, key in ipairs(keys) do
      table.insert(builder, translator[key] .. "=" .. value_or_NONE(group_spec[key]))
    end

    if #builder == 0 then
      return ""
    else
      table.insert(builder, 1, "highlight " .. group_name)
      return table.concat(builder, ' ')
    end
  end,

  -- Called when a "link" group is encountered.
  --
  -- I.e: `LuaStatement { Statement }`
  --
  -- `group_name` is the current group we're operating on (`LuaStatement`).
  -- `target_group_name` is the intended link target (`Statement`).
  -- `current_rule` is the string result of plugins before this.
  -- `entire_spec` is the entire parsed lush spec for introspection.
  --
  -- Should return the highlight rule as a string, and optionally false to
  -- prevent any future plugins from executing.
  --
  -- I.e: `return "highlight! link LuaStatement Statement"` will set the
  -- highlight rule which will be passed to the next plugin in the chain (if it
  -- exists).
  --
  -- I.e: `return "highlight! link LuaStatement Statement", false` will set the
  -- highlight rule and prevent any other plugins from running.
  make_link = function(group_name, target_group_name, current_rule, entire_spec)
    return "highlight! link " .. group_name .. " " .. target_group_name
  end
}

return lush_core

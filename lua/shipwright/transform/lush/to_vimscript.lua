--- Head exporter, accepts an AST, returns a table of strings, each
--- corresponding to a highlight rule.
local is_spec = require("shipwright.transform.lush.helpers").is_lush_spec

-- We sort our rules by the group name, but we want to make sure linked
-- groups are proximal to their parent, so linked groups are sorted by 
-- parent-name + group-name.
local sort_value = function(rule)
  local link_from, link_to = string.match(rule, "link%s+([%w_]+)%s+([%w_]+)")
  local group_name = string.match(rule, "highlight%s+([%w_]+)")
  if group_name then
    -- groups just sort by name
    return group_name
  else
    -- links sort primarily by their target, then by their own name
    return link_to .. "1" .. link_from
  end
end

-- sanitise value if empty or blank
local function value_or_NONE(value)
  if value == nil or value == '' then
    return 'NONE'
  end
  return string.gsub(tostring(value), ' ', '')
end

-- Called when a regular group is encountered.
--
-- I.e: `LuaStatement { fg = ... }`
--
-- `group_name` is the current group we're operating on (`LuaStatement`).
-- `group_spec` is the table representing the group with keys such as "fg",
--              "bg", etc *if* they are present in the theme. These values may
--              be hsl()/etc types OR strings, depending on what was used at theme
--              construction.
local function make_group(group_name, group_spec)
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

  -- pair lush keys to vim keys
  local builder = {}
  for _, key in ipairs({"fg", "bg", "sp", "gui", "blend"}) do
    table.insert(builder, translator[key] .. "=" .. value_or_NONE(group_spec[key]))
  end

  if #builder == 0 then
    return ""
  else
    table.insert(builder, 1, "highlight " .. group_name)
    return table.concat(builder, ' ')
  end
end

-- Called when a "link" group is encountered.
--
-- I.e: `LuaStatement { Statement }`
--
-- `group_name` is the current group we're operating on (`LuaStatement`).
-- `target_group_name` is the intended link target (`Statement`).
local function make_link(group_name, target_group_name)
  return "highlight! link " .. group_name .. " " .. target_group_name
end

return function(ast, config)
  assert(is_spec(ast),
    "first argument to vimscript transform must be a parsed lush spec")

  local commands = {}

  for group_name, group_def in pairs(ast) do
    if group_def.link then
      table.insert(commands, make_link(group_name, group_def.link))
    else
      table.insert(commands, make_group(group_name, group_def))
    end
  end

  -- sort the rules aphabetically  so diffs are consistenly ordered.
  -- We will sort primarily by group name, but sort links to be just
  -- after their target
  -- https://github.com/savq/melange/pull/32#issuecomment-960247099
  table.sort(commands, function(a, b)
    return sort_value(a) < sort_value(b)
  end)

  return commands
end

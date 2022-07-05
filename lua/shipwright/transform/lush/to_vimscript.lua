--- Head exporter, accepts an AST, returns a table of strings, each
--- corresponding to a highlight rule.

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

  local translator = {
    fg = "guifg",
    bg = "guibg",
    sp = "guisp",
    gui = "gui",
    blend = "blend"
  }
  -- pair lush keys to vim keys
  local rule_parts = {}
  for _, key in ipairs({"fg", "bg", "sp", "blend"}) do
    table.insert(rule_parts, translator[key] .. "=" .. value_or_NONE(group_spec[key]))
  end

  -- The gui key is a composition of boolean fields, which may have been set
  -- directly, or extracted from the `gui` key into separate components during
  -- compilation. We will individually iterate each possible key and generate
  -- the gui string, or set it to NONE if all keys were false/nil.
  local gui = {}
  local formatters = {
    "bold", "italic", "underline", "underlineline",
    "undercurl", "underdot", "underdash", "strikethrough",
    -- https://github.com/rktjmp/lush.nvim/issues/96
    -- 0.8 key renames
    "underdouble", "underdotted", "underdashed",
    "reverse", "standout", "nocombine"
  }
  for _, key in ipairs(formatters) do
    if group_spec[key] then
      table.insert(gui, key)
    end
  end
  local gui_value = value_or_NONE(table.concat(gui, ","))
  table.insert(rule_parts, string.format("gui=%s", gui_value))

  if #rule_parts == 0 then
    return ""
  else
    table.insert(rule_parts, 1, "highlight " .. group_name)
    return table.concat(rule_parts, ' ')
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
  local is_spec = require("shipwright.transform.lush.helpers").is_lush_spec
  local group_sort_value  = require("shipwright.transform.lush.helpers").group_sort_value
  assert(is_spec(ast),
    "first argument to vimscript transform must be a parsed lush spec")

  -- compiled table is more normalised, so we'll use that to build our rules
  local compiled = require("lush.compiler")(ast)

  local group_strings = {}
  for group_name, group_def in pairs(compiled) do
    if group_def.link then
      table.insert(group_strings, {
        cmd = make_link(group_name, group_def.link),
        sort_key = group_sort_value(group_name, group_def)
      })
    else
      table.insert(group_strings, {
        cmd = make_group(group_name, group_def),
        sort_key = group_sort_value(group_name, group_def)
      })
    end
  end

  -- sort the rules aphabetically  so diffs are consistenly ordered.
  -- We will sort primarily by group name, but sort links to be just
  -- after their target
  -- https://github.com/savq/melange/pull/32#issuecomment-960247099
  table.sort(group_strings, function(a, b)
    return a.sort_key < b.sort_key
  end)

  -- we only want the actual commands
  local commands = {}
  for _, group in ipairs(group_strings) do
    table.insert(commands, group.cmd)
  end
  return commands
end

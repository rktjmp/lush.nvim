-- compiles a given parsed lush spec into table usable by nvim_set_hl

-- attrs for a linking group
local function link_group_to_attrs(group_def)
  -- links are just links and need no extra work
  return {link = group_def.link}
end

-- attrs for a regular highlight group
local function normal_group_to_attrs(group_def)
  -- We copy over most keys given, relying on the user to have used valid keys
  -- but do manually tweak some.
  --
  -- fg, bg and sp may be hsl values or at least anything that responds to
  -- tostring and must be intentionally converted to strings.
  --
  -- gui is a legacy vim-hl field which may contain a collection of format
  -- modifiers which we will split out. The values in gui have lower precedence
  -- over any explicit format modifier key-values given.
  --
  -- lush is a special lush-namespace key which should be discarded.
  --
  -- link is also discarded as we have our own syntax for linking groups.

  -- copy out extra keys, excluding our edge cases, we'll merge these later.
  local extra_attrs = {}
  local excluded = function(key)
    for _, ex in ipairs({"fg", "bg", "sp", "link", "lush", "gui"}) do
      if ex == key then
        return true
      end
    end
    return false
  end
  for key, value in pairs(group_def) do
    if not excluded(key) then
      extra_attrs[key] = value
    end
  end

  -- start with basic colors and blending as they're uncomplicated
  local attrs = {
    -- color values, may be hsl value or plain string
    fg = (group_def.fg and tostring(group_def.fg)),
    bg = (group_def.bg and tostring(group_def.bg)),
    sp = (group_def.sp and tostring(group_def.sp)),
    -- blend is an int value
    blend = group_def.blend
  }

  -- if gui key is present, split it out to component flags
  if group_def.gui then
    -- gui strings may have mixed case, commas and spaces so we'll try
    -- to be pretty forgiving in terms of what we'll match.
    local gui = string.lower(group_def.gui)
    attrs.bold = (string.match(gui, "[^%w]?bold[^%w]?") ~= nil)
    attrs.italic = (string.match(gui, "[^%w]?italic[^%w]?") ~= nil)
    attrs.underline = (string.match(gui, "[^%w]?underline[^%w]?") ~= nil)
    attrs.underlineline = (string.match(gui, "[^%w]?underlineline[^%w]?") ~= nil)
    attrs.undercurl = (string.match(gui, "[^%w]?undercurl[^%w]?") ~= nil)
    attrs.underdot = (string.match(gui, "[^%w]?underdot[^%w]?") ~= nil)
    attrs.underdash = (string.match(gui, "[^%w]?underdash[^%w]?") ~= nil)
    attrs.strikethrough = (string.match(gui, "[^%w]?strikethrough[^%w]?") ~= nil)
    attrs.reverse = (string.match(gui, "[^%w]?reverse[^%w]?") ~= nil)
    -- not supported in highlight.c
    -- attrs.inverse = (string.match(gui, "[^%w]?inverse[^%w]?") ~= nil)
    attrs.standout = (string.match(gui, "[^%w]?standout[^%w]?") ~= nil)
    attrs.nocombine = (string.match(gui, "[^%w]?nocombine[^%w]?") ~= nil)
  end

  -- now re-merge any extra attrs which may override gui settings
  for key, value in pairs(extra_attrs) do
    attrs[key] = value
  end

  return attrs
end

-- keys as seen from:
-- https://github.com/neovim/neovim/blob/6d4180a0d20d0b730b6e64acdac39261f52a9277/src/nvim/highlight.c#L813
-- docs say "like synIDattr" but we don't use "fg#" and we can also send in "link"
local function compile(parsed_spec, options)
  local groups = {}
  for group, def in pairs(parsed_spec) do
    if def.link then
      groups[group] = link_group_to_attrs(def)
    else
      groups[group] = normal_group_to_attrs(def)
    end
  end
  return groups
end

return compile

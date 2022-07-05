-- compiles a given parsed lush spec into table usable by nvim_set_hl

-- attrs for a linking group
local function link_group_to_attrs(group_def)
  -- links are just links and need no extra work
  return {link = group_def.link}
end

-- attrs for a regular highlight group
local function normal_group_to_attrs(group_def)
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
  --
  -- ideally future lush versions will just accept any key given (requires
  -- removing the whitelist in parser) and pass those on to nvim_set_hl but for
  -- now we will keep changes minimal and only accept "classic" keys.

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
    -- for a nicer pattern match, we wrap the gui string in spaces
    -- so we can always match against a non-word char, otherwise
    -- we can spuriously match "semibold" against "bold"
    local gui = " " .. string.lower(group_def.gui) .. " "
    local maybe_set = function(modifier)
      local pat = string.format("[^%%w]%s[^%%w]", modifier)
      return string.match(gui, pat) and true or nil
    end
    local formatters = {
      "bold", "italic", "underline", "underlineline",
      "undercurl", "underdot", "underdash", "strikethrough",
      -- https://github.com/rktjmp/lush.nvim/issues/96
      -- 0.8 key renames
      "underdouble", "underdotted", "underdashed",
      "reverse", "standout", "nocombine"
    }
    for i, formatter in ipairs(formatters) do
      attrs[formatter] = maybe_set(formatter)
    end
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

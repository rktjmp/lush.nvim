local function error_to_string(error)
  local str = "group = '"..error.on .. "' message = '" .. error.type .."': " .. error.msg
  if error.also then
    str = str .. " -> " .. error_to_string(error.also)
  end
  return str
end

local function group_error(table)
  return function()
    return nil, {
      on = table.on or "unspecified_group",
      type = table.type or "unspecified_type",
      msg = table.msg or "",
      also = table.also,
    }
  end
end

-- Think Pad
--
-- All groups are functions, an invalid group may exist until it is attempted
-- to be resolved, which is the act of calling a group.

-- All values will be functions? Or at least we wrap all values? 

-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local wrap_group = function(group_name, group_options)

  -- smoke test

  if type(group_options) ~= "table" then
    return group_error({
      on = group_name,
      msg = "Options for " .. group_name .. " was " ..
            type(group_options) .. " but must be table.",
      type = "definition_must_be_table"
    })
  end

  if group_options.__name then
    return group_error({
      on = group_name,
      msg = "Invalid key, __name is reserved",
      type = "reserved_keyword"
    })
  end

  -- group seems ok to continue

  -- A group looks like:
  -- {
  --   __name = "Normal",
  --   __type = "lush_group",
  --   ...?
  -- }

  -- We want to normalize the internal interface to any value,
  -- so ensure they are all callable.
  -- This means lush_groups get called, and resolved,
  -- while regular values get called, and returned.
  -- TODO: potentially __index and wrap nil returns?
  local wrapped_opts = {}
  for key, val in pairs(group_options) do
    if type(val) == "table" and val.__type == "lush_group_placeholder" then
      return group_error({
        on = group_name,
        msg = "Attempt to use group " .. val.__name ..
              " as value, but group isn't defined",
        type = "undefined_group"
      })
    end
    if type(val) == "table" and val.__type == "lush_group" then
      local check = val[key]
      if check == nil then
        return group_error({
          on = group_name,
          msg = "Attempted to infer value for " ..  key ..
                " from " .. val.__name ..  " but " .. val.__name ..
                " has no " .. key..  " key",
          type = "target_missing_inferred_key"
        })
      end
      wrapped_opts[key] = val[key]
    else
      wrapped_opts[key] = val
    end
  end

  -- Normal.fg.ro
  -- Group.index_for_key fg -> hsl

  -- fg: Normal.ro
  --  Group.index_for_key(ro) -> Norma.fg.hsl


  -- Define the actual group table
  -- It defines __name (name of group) and __type ("lush_group")
  -- When indexed, it returns
  --    either the above keys, or
  --    will attempt to provide an inferred value for a key
  --    Normally this will simply mean the key-value from
  --    the group options, but if the value would be another group,
  --    we attempt to chain the key request to that group.

  return setmetatable({}, {

    -- When the group is index'd, return our special keys
    -- or proxy out to the wrapped options (which may proxy again to
    -- a linked group)
    __index = function(_, key)
      if key == "__name" then
        return group_name
      elseif key == "__type" then
        return "lush_group"
      else
        return wrapped_opts[key]
      end
    end,

    -- When the group is called, return the wrapped options, consider
    -- the group resolved. If the group is called, it is an error, it's
    -- aready resolved and likely re-calling is an attempt to redefine.
    -- It's difficult to detect this elsewhere.
    __call = function()
      return setmetatable(wrapped_opts, {
        __call = group_error({
          on = group_name,
          type = "group_redefined",
          msg = "Attempted to redefine group: " .. group_name
        })
      })
    end
  })
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, link descriptor
local wrap_link = function(group_name, group_options)
  local link_to = group_options[1]

  if link_to.__type == "lush_group_placeholder" then
    -- error group when resolve is attempted
    return group_error({
      on = group_name,
      msg = "Linked group was never defined, or was not defined before use: " .. link_to.__name,
      type = "invalid_link_name"
    })
  end

  return setmetatable({}, {
    __index = function(_, key)
      if key == "__name" then
        return group_name
      elseif key == "__type" then
        return "lush_group_link"
      else
        -- proxy
        return link_to[key]
      end
    end,
    __call = function()
      return {
        link = link_to.__name
      }
    end
  })
end

local wrap = function(group_name, group_options)
  local group_type = function(opts)
    -- order of these checks are important, they cascade protections
    if type(opts) ~= "table" or #group_options > 1 or group_options == {} then
      -- !{} or {} or { group, group, ... } -> invalid
      return nil, "invalid group_options"
    elseif #group_options == 0 then
      -- { fg = val, ... } -> group with group_options
      return "group"
    elseif #group_options == 1 then
      -- #group_options == 1, link to group or inherit
      -- { group, fg = val } -> inherit from group, OR
      -- { group }, -> link
      local opts_is_map = false
      for k,_ in pairs(group_options) do
        if type(k) ~= "number" then opts_is_map = true end
      end

      if opts_is_map then
        -- group has a numberical index (because # == 1)
        -- but also has non-numeric keys, so we're inheriting
        return "inherit"
      else
        return "link"
      end
    else
      return nil, "unknown_options"
    end
  end

  local type, err = group_type(group_options)

  if type == "group" then
    return wrap_group(group_name, group_options)
  end

  if type == "inherit" then
    -- extract options and merge, then wrap as normal
    local link = group_options[1]
    -- TODO check link is not placeholder
    local merged = {
      fg = group_options.fg or link.fg,
      bg = group_options.bg or link.bg,
      gui = group_options.gui or link.gui,
      sp = group_options.sp or link.sp
    }
    return wrap_group(group_name, merged)
  end

  if type == "link" then
    return wrap_link(group_name, group_options)
  end

  return nil, err
end

local validate_group_def = function(group_def)
  -- TODO allow empty def to test
  -- if not group_def then
  --   return false, {
  --     type = "no_definition",
  --   }
  -- end
  if false and group_def["__name"] then
    -- this should return a function so parse can see a function
    -- instead of a a table, which it will recognize as an error,
    -- then call the function to extract the error.
    -- We return the function *now* as apposed to the no_definition
    -- error because the group_def function is actually run when
    -- lua expands our lush-spec-list, it just happens that the
    -- spec is invalid.
    -- In the case of no_definition, the function group_def function
    -- is never run, until the parser does to retrieve the error
    return function()
      return false, {
        type = "__name_reserved_keyword",
      }
    end
  end
  return true
end

local resolve_group_bindings = function(group)
  return group()
end


local parse = function(lush_spec_fn, options)
  assert(type(lush_spec_fn) == "function", "Must supply function to parser")

  setfenv(lush_spec_fn, setmetatable({}, {
    -- Lua only calls __index if the key doesn't already exist.
    __index = function(lush_spec, group_name)

      -- attempted to access an unknown group name
      -- We will provide an table which can be queried for it's type
      -- (undefined_group), and name (group_name), and may be
      -- called (with group_def) to create an group table.

      local define_group = function(_, group_def)
        -- _ is the group_placeholder, which we do not require
        -- wrap group in group or link handler
        local group = wrap(group_name, group_def)
        -- insert group into spec env, this allows us to
        -- reference this group by name in other groups
        -- replace the previously undefined place holder
        lush_spec[group_name] = group

        -- this ends up in the spec's return table
        return group
      end

      -- This placeholder will sit in the env until we call it, which will 
      -- replace the placeholder with the true group.
      -- Mostly this is useful for error detection, because in correct practice, 
      -- you will immediately call the placeholder after creation.
      local group_placeholder = setmetatable({}, {
        __call = define_group,
        __index = function(_, key)
          if key == "__name" then
            return group_name
          elseif key == "__type" then
            return "lush_group_placeholder"
          else
            return nil
          end
        end
      })

      -- define that we've seen this group name in the spec
      lush_spec[group_name] = group_placeholder

      -- return the group definer, which will be called immediately
      -- in most cases.
      return group_placeholder
    end
  }))

  -- generate spec
  local spec = lush_spec_fn()
  if not spec then error("malformed lush-spec", 6) end

  -- we will return the spec in a normalized form
  local parsed = setmetatable({}, {
    -- for error protection, we need to be able to infer the correct
    -- type of the table, but we don't want the key to be iterable.
    __index = function(t, key)
      if key == "__type" then
        return 'parsed_lush_spec'
      else
        return rawget(t, key)
      end
    end
  })

  for _, group in ipairs(spec) do
    -- attempt to resolve group
    --local ast, e = resolve_group_bindings(group)
    local ast, e = group()

    if e then
      error("lush.parser.parse error: " .. error_to_string(e), 4)
    end

    parsed[group.__name] = ast
  end

  return parsed
end

return parse

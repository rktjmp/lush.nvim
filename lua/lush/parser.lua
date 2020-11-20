local function error_to_string(error)
  local str = "group = '"..error.on .. "' message = '" .. error.type .."'"
  if error.also then
    str = str .. " -> " .. error_to_string(error.also)
  end
  return str
end

-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local wrap_group = function(name, group_options)

  -- wrapped groups can ...
  -- fg = Group.fg -> access options value
  -- fg = Group -> infer group.fg

  -- A group looks like:
  -- {
  --   __name = "Normal",
  --   __type = "lush_group",
  --   ...?
  -- }
  --

  -- We want to normalize the internal interface to any value,
  -- so ensure they are all callable.
  -- This means lush_groups get called, and resolved,
  -- while regular values get called, and returned.
  local wrapped_opts = {}
  for key, val in pairs(group_options) do
    if val.__type == "lush_group_placeholder" then
      error("undef"..val.__name)
    end
    -- TODO: potentially __index and wrap nil returns?
    if val.__type == "lush_group" then
      wrapped_opts[key] = val[key]
    else
      wrapped_opts[key] = val
    end
  end

  -- Define the actual group table
  -- It defines __name (name of group) and __type ("lush_group")
  -- When indexed, it returns
  --    either the above keys, or
  --    will attempt to provide an inferred value for a key
  --    Normally this will simply mean the key-value from 
  --    the group options, but if the value would be another group,
  --    we attempt to chain the key request to that group.

  return setmetatable({}, {
    __index = function(_, key)
      if key == "__name" then
        return name
      elseif key == "__type" then
        return "lush_group"
      else
        return wrapped_opts[key]
      end
    end,

    __call = function()
      -- unpack wrapped_opts into values
      local builder = {}
      for key, val in pairs(wrapped_opts) do
        builder[key] = val
      end

      return setmetatable(wrapped_opts, {
        __call = function()
          error("redefined")
        end
      })
    end
  })
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, link descriptor
local wrap_link = function(name, link_to)
  return setmetatable({ }, {
    __index = function(_, key)
      if key == "__name" then
        return name
      elseif key == "__type" then
        return "lush_group_link"
      else
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

local wrap = function(name, args)
  local is_link = function(opts)
    return getmetatable(opts[1]) ~= nil
  end

  return is_link(args) and
         wrap_link(name, args[1]) or wrap_group(name, args)
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
        -- smoke test the group definition
        local valid, e = validate_group_def(group_def)
        if not valid then
          return nil, {
            on = group_name,
            type = e.type,
          }
        end

        -- wrap group in group or link handler
        local group = wrap(group_name, group_def)

        -- insert group into spec env, this allows us to
        -- reference this group by name in other groups
        -- replace the previously undefined place holder
        lush_spec[group_name] = group

        return group
      end

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

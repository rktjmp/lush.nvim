-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local wrap_group = function(name, options)
  return setmetatable({ }, {
    __index = function(_, key)
      if key == "__name" then
        return name
      else
        return options[key]
      end
    end,
    __call = function()
      return options
    end
  })
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, returns proxied group
local wrap_link = function(name, link_to)
  return setmetatable({ }, {
    __index = function(_, key)
      if key == "__name" then
        return name
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
  return is_link(args) and wrap_link(name, args[1]) or  wrap_group(name, args)
end

local parse = function(fn)
  setfenv(fn, setmetatable({ }, {
    __index = function(env, group_name)
      return function(group_def)
        if group_def["_name"] then
          error("Error: group '"
                .. group_name
                .. "' invalid, '__name' is a reserved")
        end

        -- wrap group in accessors for chaining,
        -- insert into fenv for referencing,
        -- return the group to add to ... AST [sic]
        local group = wrap(group_name, group_def)
        env[group_name] = group
        return group
      end
    end
  }))

  -- turn AST [sic] into logical map
  local parsed = {}
  for _, group in ipairs(fn()) do
    parsed[group.__name] = group()
  end
  return parsed
end

return parse

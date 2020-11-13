local function error_to_string(error)
  local str = error.on .. ": " .. error.type
  if error.also then
    str = str .. " -> " .. error_to_string(error.also)
  end
  return str
end
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
      for _, v in pairs(options) do
        -- if type(v) == function, we probably have something like this:
        --    Group { UndefinedGroup }
        -- which translates to
        --    Group({UndefinedGroup})
        -- UndefinedGroup will be set to a function (correctly) in the env
        -- table, but it's never run to actually define the group
        --
        -- In the future, it may make sense to have a function embedded
        -- without being called, but for now it's an easy way to detect
        -- this error
        if type(v) == "function" then
          -- run the function so we can get it's error, so we can present
          -- a nicer error to the user (I.e. the root cause is in V, not here)
          local _, e = v()
          if e then
            return nil, {
              type = "bad_reference",
              on = name,
              also = e
            }
          end
        end
      end
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

  return is_link(args) and
         wrap_link(name, args[1]) or wrap_group(name, args)
end

local parse = function(fn)
  setfenv(fn, setmetatable({ }, {
    __index = function(env, group_name)
      return function(group_def)
        if not group_def then
          return nil, {
            type = "no_definition",
            on = group_name,
          }
        end
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
    local ast, e = group()
    if e then
      error("lush.parser.parse error: " .. error_to_string(e))
    end
    parsed[group.__name] = ast
  end
  return parsed
end

return parse

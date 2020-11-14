local function error_to_string(error)
  local str = "group = '"..error.on .. "' message = '" .. error.type .."'"
  if error.also then
    str = str .. " -> " .. error_to_string(error.also)
  end
  return str
end
-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local wrap_group = function(name, options)
  return setmetatable({}, {
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
        -- table, but it's never run to expand into the group
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
      return setmetatable(options, {
        __call = function()
          -- TODO: pretty terrible way to detect this error
          return nil, {type =  "may_have_redefined_group", on = name}
        end
      })
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
  setfenv(fn, setmetatable({}, {
    -- remember, when someting gets 'indexed' in our lush spec,
    -- we define the function for that group, then insert it into
    -- the function env. Next time the group is referenced, it isn't
    -- indexed since a function with the right name exsts, so that value
    -- is assigned directly. This means we don't have to return 'already
    -- defined groups' in this index metamethod.
    __index = function(env, group_name)
      return function(group_def)
        if not group_def then
          return nil, {
            type = "no_definition",
            on = group_name,
          }
        end
        if group_def["__name"] then
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
            return nil, {
              type = "__name_reserved_keyword",
              on = group_name
            }
          end
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

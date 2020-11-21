local function error_to_string(error)
  local str = "group = '"..error.on .. "' message = '" .. error.type .."': " .. error.msg
  if error.also then
    str = str .. " -> " .. error_to_string(error.also)
  end
  return str
end

local function allowed_option_keys()
  -- note, sometimes `1` is manually inserted into allowed options,
  -- since it's OK in some edge cases (inheritance, links)
  return {"fg", "bg", "sp", "gui", "lush"}
end

-- groups should define their error state "on resolve",
-- that is to say, when they're called after parsing into the AST.
-- So this function *returns a function*, which when called, indicates
-- an error to the parser.
local function group_error(table)
  return function()
    -- effectively return nil-group, error
    return nil, {
      on = table.on or "unspecified_group",
      type = table.type or "unspecified_type",
      msg = table.msg or "",
      also = table.also,
    }
  end
end

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

  -- We want to normalize the internal interface to any value,
  -- so ensure they are all callable.
  -- This means lush_groups get called, and resolved,
  -- while regular values get called, and returned.
  -- TODO: potentially __index and wrap nil returns?

  local wrapped_opts = {}
  for key, tuple in pairs(group_options) do
    local val, kind = unpack(tuple)
    local internal_type = kind == "internal"

    if internal_type then
      if type(val) == "table" and val.__type == "lush_group_placeholder" then
        if val.__name == group_name then
          return group_error({
            on = group_name,
            msg = "Attempt to reference group " .. group_name ..
                  " inside " .. val.__name,
            type = "circular_self_reference"
          })
        else
          return group_error({
            on = group_name,
            msg = "Attempt to reference group " .. val.__name ..
                  " as value, but group isn't defined before " .. group_name,
            type = "undefined_group"
          })
        end
      end
      if type(val) == "table" and val.__type == "lush_group" then
        -- don't return nil on inferred keys
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

        -- key has value, return the value
        wrapped_opts[key] = val[key]

        return group_error({
          on = group_name,
          msg = "Property inference is currently disabled",
          type = "feature_disabled"
        })
      else
        wrapped_opts[key] = val
      end
    else
      wrapped_opts[key] = val
    end
  end

  -- Define the actual group table
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

local wrap_inherit = function(group_name, group_options)
  local link, kind = unpack(group_options[1])

  if group_name == link.__name then
    return group_error({
      on = group_name,
      type = "circular_self_reference",
      msg = "Attempt to inherit properties from self",
    })
  end

  if link.__type == "lush_group_placeholder" then
    return group_error({
      on = group_name,
      msg = "Parent group '" .. group_name .. "' was never defined," ..
            "or was not defined before use.",
      type = "invalid_parent_name"
    })
  end


  -- merge values from parent if not present in child
  local merged = {}
  for _, key in ipairs(allowed_option_keys()) do
    local tuple = group_options[key]
    if tuple then
      merged[key] = tuple
    else
      merged[key] = {link[key], nil}
    end
  end

  return wrap_group(group_name, merged)
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, link descriptor
local wrap_link = function(group_name, group_options)
  local link_to, kind = unpack(group_options[1])

  if link_to.__name == group_name then
    return group_error({
      on = group_name,
      type = "circular_self_reference",
      msg = "Attempt to link to self",
    })
  end

  if link_to.__type == "lush_group_placeholder" then
    -- error group when resolve is attempted
    return group_error({
      on = group_name,
      msg = "Linked group '" .. link_to.__name .. "' was never defined," ..
            "or was not defined before use.",
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

local wrap = function(group_type, group_name, group_options)
  if group_type == "group" then
    return wrap_group(group_name, group_options)
  end

  if group_type == "inherit" then
    return wrap_inherit(group_name, group_options)
  end

  if group_type == "link" then
    return wrap_link(group_name, group_options)
  end

  return nil, "unknow_group_type"
end

local group_type_or_error = function(group_def)
  -- order of these checks are important, they cascade protections
  if type(group_def) ~= "table" or group_def == {} then
    -- !{} or {} or { group, group, ... } -> invalid
    return nil, "invalid group_options"
  elseif #group_def > 1 then
    return nil, "too_many_parents"
  elseif #group_def == 0 then
    -- { fg = val, ... } -> group with group_def
    return "group"
  elseif #group_def == 1 then
    -- #group_def == 1, link to group or inherit
    -- { group, fg = val } -> inherit from group, OR
    -- { group }, -> link
    local opts_is_map = false
    for k,_ in pairs(group_def) do
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

local group_name_or_error = function(group_name)
  if not string.match(group_name, "^[a-zA-Z]") then
    return nil, "invalid_group_name"
  end

  if string.match(group_name, "^ALL$") or
     string.match(group_name, "^NONE$") or
     string.match(group_name, "^ALLBUT$") or
     string.match(group_name, "^contained$") or
     string.match(group_name, "^contains$") then
     return nil, "invalid_group_name"
   end

   return group_name
end


local group_error_for_reason = function(reason, group_name, group_options)
  return group_error({
    on = group_name,
    type = reason,
    msg = "not implemented yet"
  })
end

local parse = function(lush_spec_fn, options)
  assert(type(lush_spec_fn) == "function", "Must supply function to parser")

  local seen_groups = {}
  setfenv(lush_spec_fn, setmetatable({}, {
    -- Lua only calls __index if the key doesn't already exist.
    __index = function(lush_spec_env, group_name)

      -- attempted to access an unknown group name
      -- We will provide an table which can be queried for it's type
      -- (undefined_group), and name (group_name), and may be
      -- called (with group_def) to create an group table.

      -- _ is the group_placeholder, which we do not require
      local define_group = function(_, group_def)

        -- Smoke test the top surface of the group. We this will find basic
        -- definition mistakes but interals of a definition may still fail
        -- at a later point.
        local err, group_type
        group_name, err = group_name_or_error(group_name)
        if err then return group_error_for_reason(err) end
        group_type, err = group_type_or_error(group_def)
        if err then return group_error_for_reason(err, group_name, group_def) end

        -- If a value is in the lush_spec_env, it's a group def,
        -- we need to flag this early here, so we can check for
        -- placeholders that haven't been properly resolved, but we
        -- can't rely on just accessing the .__type key because
        -- external values may respond with an error.
        -- (AKA hsl.__type is an error of "unsupported modifier")
        local protected = {}

        for _, key in ipairs(allowed_option_keys()) do
          local val = group_def[key]
          if val then
            local is_group = seen_groups[val]
            local tuple = {val, is_group and "internal" or "external"}
            protected[key] = tuple
          end
        end

        -- inhert and link both should have a [1] key, but we keep out out of 
        -- the allowed options check for ease of use elsewhere.
        if group_def[1] and (group_type == "inherit" or group_type == "link") then
          local val = group_def[1]
          local is_group = seen_groups[val]
          local tuple = {val, is_group and "internal" or "external"}
          protected[1] = tuple
        end

        -- wrap group in group or link handler
        local group, err = wrap(group_type, group_name, protected)

        if err then
          -- TODO make this less yuck.
          if err == "too_many_parents" then
            group = group_error({
              on = group_name,
              type = "too_many_parents",
              msg = "Group '" .. group_name .. "' tries to inherit from too many parents.",
            })
          elseif err == "invalid_group_name" then
            group = group_error({
              on = group_name,
              type = err,
              msg = "Group '" .. group_name ..
                    "' name is invalid, must begin with a letter and not be " ..
                    "one of the reserved keywords: ALL NONE ALLBUT " ..
                    "contains contained."
            })
          else
            -- unknown error reason
            group = group_error({
              on = group_name,
              type = err,
              msg = "Spec invalid for unrecognized reason.",
            })
          end
        end

        -- insert group into spec env, this allows us to
        -- reference this group by name in other groups
        -- replace the previously undefined place holder
        lush_spec_env[group_name] = group

        seen_groups[group] = group
        seen_groups[group_name] = group

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
      lush_spec_env[group_name] = group_placeholder

      seen_groups[group_placeholder] = group_placeholder
      seen_groups[group_name] = group_placeholder

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
      error("Lush-spec Error:" .. error_to_string(e), 4)
    end

    parsed[group.__name] = ast
  end

  return parsed
end

return parse

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

local error_map_for_code = function(code, context)
  local base = {
    on = context.on,
    type = code
  }
  local map = {
    circular_self_link = function()
      return "Attempt to link self"
    end,
    invalid_link_name = function()
      return "Linked group '" .. context.link_name .. "' was never defined," ..
              "or was not defined before use."
    end,
    defintion_must_be_table = function()
      return "Options for " .. context.on .. " was " ..
             context.type .. " but must be table."
    end,
    reserved_keyword = function()
      return "Invalid key, __name is reserved"
    end,
    undefined_group = function()
      return "Attempt to reference group " .. context.missing ..
            " as value, but group isn't defined before " .. context.on
    end,
    inference_disabled = function()
      return "Inference feature disabled"
    end,
    group_redefined = function()
      return "Attempted to redefine group: " .. context.on
    end,
    circular_self_inherit = function()
      return "Attempted to inherit from self"
    end,
    invalid_parent = function()
      return "Parent group '" .. context.missing .. "' was never defined, " ..
             "or was not defined before use."
    end,
    too_many_parents = function()
      return "Group " .. context.on .. " tries to inherit from too many parents"
    end
  }

  if map[code] then 
    base.msg = map[code]()
    return base
  else
    base.msg = "No message avaliable"
    return base
  end
end

local error_for = function(code, context)
  return group_error(error_map_for_code(code, context))
end

-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local wrap_group = function(group_name, group_options)
  -- smoke test
  if type(group_options) ~= "table" then
    return  error_for("definition_must_be_table", {
      on = group_name,
      type = type(group_options)
    })
  end
  if group_options.__name then
    return error_for("reserved_keyword", {on = group_name})
  end

  -- We want to normalize the internal interface to any value,
  -- so ensure they are all callable.
  -- This means lush_groups get called, and resolved,
  -- while regular values get called, and returned.
  -- TODO: potentially __index and wrap nil returns?

  local proxied_options = {}
  for key, tuple in pairs(group_options) do
    local val, kind = unpack(tuple)

    if kind == "lush_group_placeholder" then
      -- placeholder groups that get this far are an error, halt.
      if val.__name == group_name then
        return error_for("circular_self_reference", {on = group_name})
      else
        return error_for("undefined_group", {on = group_name, missing = val.__name})
      end
    end

    if kind == "lush_group" then
      -- WIP for property inference
      -- don't return nil on inferred keys
      --  local check = val[key]
      --  if check == nil then
      --    return group_error({
      --      on = group_name,
      --      msg = "Attempted to infer value for " ..  key ..
      --      " from " .. val.__name ..  " but " .. val.__name ..
      --      " has no " .. key..  " key",
      --      type = "target_missing_inferred_key"
      --    })
      --  end

      --  -- lush group referenced has key requested,
      --  -- so proxy this would-be group's value to the proxy group
      --  proxied_options[key] = val[key]
      return error_for("inference_disabled", {on = group_name})
    end

    -- no group to proxy to, just map key to value
    proxied_options[key] = val
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
        return proxied_options[key]
      end
    end,

    __call = function()
      -- return proxied options, but also guard against those
      -- options being called, which implies a redefinition attempt error
      return setmetatable(proxied_options, {
        -- attempt to redefine group
        __call = error_for("group_redefined", {on = group_name})
      })
    end
  })
end

local wrap_inherit = function(group_name, group_options)
  local link, kind = unpack(group_options[1])

  if group_name == link.__name then
    return error_for("circular_self_inherit", {on = group_name})
  end
  if link.__type == "lush_group_placeholder" then
    return error_for("invalid_parent", {on = group_name, missing = link.__name})
  end

  -- merge values from parent if not present in child
  local merged = {}
  for _, key in ipairs(allowed_option_keys()) do
    local tuple = group_options[key]
    if tuple then
      merged[key] = tuple
    else
      merged[key] = {link[key], type(link[key])}
    end
  end

  return wrap_group(group_name, merged)
end


local validate_group_link = function(name, options)
  local link_to, kind = unpack(options[1])

  if link_to.__name == name then
    return false, error_map_for_code("circular_self_link", {on = name})
  end

  if link_to.__type == "lush_group_placeholder" then
    -- error group when resolve is attempted
    return false, error_map_for_code("invalid_link_name", {on = name, link_name = link_to.__name})
  end

  return true
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, link descriptor
local wrap_link = function(group_name, group_options)
  local _, err = validate_group_link(group_name, group_options)
  if err then return group_error(err) end

  local link_to, kind = unpack(group_options[1])
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
  if group_type == "group" then return wrap_group(group_name, group_options) end
  if group_type == "inherit" then return wrap_inherit(group_name, group_options) end
  if group_type == "link" then return wrap_link(group_name, group_options) end
  return nil, "unknow_group_type"
end

local infer_group_type = function(group_def)
  if #group_def == 0 then
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

local validate_base_group_definition = function(group_def)
  -- order of these checks are important, they cascade protections
  if type(group_def) ~= "table" or group_def == {} then
    -- !{} or {} or { group, group, ... } -> invalid
    return false, "invalid group_options"
  elseif #group_def > 1 then
    return false, "too_many_parents"
  end

  return true
end

local validate_group_type = function(kind, group_def)
end

local validate_group_name = function(group_name)
  if not string.match(group_name, "^[a-zA-Z]") or
     string.match(group_name, "^ALL$") or
     string.match(group_name, "^NONE$") or
     string.match(group_name, "^ALLBUT$") or
     string.match(group_name, "^contained$") or
     string.match(group_name, "^contains$") then
     return false, "invalid_group_name"
   end

   return true
end

local parse = function(lush_spec_fn, options)
  assert(type(lush_spec_fn) == "function", "Must supply function to parser")

  local group_lookup = {}
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
        _, err = validate_group_name(group_name)
        if err then return error_for(err, {on = group_name}) end

        local _, err = validate_base_group_definition(group_def)
        if err then return error_for(err, {on = group_name}) end

        group_type = infer_group_type(group_def)

        local _, err = validate_group_type(type, group_def)

        -- If a value is in the lush_spec_env, it's a group def,
        -- we need to flag this early here, so we can check for
        -- placeholders that haven't been properly resolved, but we
        -- can't rely on just accessing the val.type because
        -- external values may respond with an error.
        -- (AKA hsl.__type is an error of "unsupported modifier")
        local protected = {}
        for _, key in ipairs(allowed_option_keys()) do
          local val = group_def[key]
          if val then
            local is_group = group_lookup[val]
            local tuple = {val, is_group and val.__type or type(val)}
            protected[key] = tuple
          end
        end

        -- inhert and link both should have a [1] key, but we keep out out of
        -- the allowed options check for ease of use elsewhere.
        if group_def[1] and (group_type == "inherit" or group_type == "link") then
          local val = group_def[1]
          local is_group = group_lookup[val]
          local tuple = {val, is_group and val.__type or type(val)}
          protected[1] = tuple
        end

        -- wrap group in group or link handler
        local group, err = wrap(group_type, group_name, protected)

        if err then
          group = error_for(err, {on = group_name})
        end

        -- insert group into spec env, this allows us to
        -- reference this group by name in other groups
        -- replace the previously undefined place holder
        lush_spec_env[group_name] = group

        group_lookup[group] = group
        group_lookup[group_name] = group

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

      group_lookup[group_placeholder] = group_placeholder
      group_lookup[group_name] = group_placeholder

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

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
local function resolves_as_error(table)
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

local error_for = function(code, context)
  local base = {
    on = context.on,
    msg = "No message avaliable",
    type = code
  }
  local message_map = {
    invalid_group_options = function()
      return "Group defition must be a table"
    end,
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
    end,
    group_value_is_group = function()
      return "Group " .. context.on .. "." .. context.key .. " must be a value, not a group"
    end
  }

  if message_map[code] then base.msg = message_map[code]() end
  return base
end

local is_group = function(kind)
  return kind == "lush_group" or kind == "lush_placeholder_group"
end

local is_placeholder_group = function(kind)
  return kind == "lush_group_placeholder" 
end

local is_concrete_group = function(kind)
  return kind == "lush_group"
end

local enforce_generic_group_name = function(name, opts)
  if not string.match(name, "^[a-zA-Z]") or
     string.match(name, "^ALL$") or
     string.match(name, "^NONE$") or
     string.match(name, "^ALLBUT$") or
     string.match(name, "^contained$") or
     string.match(name, "^contains$") then
     return {"invalid_group_name"}
   end
end

local enforce_generic_definition_type = function(name, opts)
  if type(opts) ~= "table" or opts == {} then
    -- !{} or {} or { group, group, ... } -> invalid
    return {"invalid_group_options"}
  end
end

local enforce_generic_one_parent = function(name, opts)
  if #opts > 1 then
    return {"too_many_parents"}
  end
end

local enforce_definition_is_table = function(name, opts)
  -- NB: technically the initial parser will validate the type
  --     so this is unlikely to ever fail
  --     retained for clarity reasons (for now)
  if type(opts) ~= "table" or opts == {} then
    return {"definition_must_be_table", {was = type(opts)}}
  end
end

local enforce_no_protected_keys = function(name, opts)
  -- NB: technically __name is dropped before this is ever called,
  --     retained as a validation for clarity reasons (for now)
  if opts.__name ~= nil then
    return {"reserved_keyword"}
  end
end

local wrap_group_enforce_no_placeholders = function(name, opts)
  for key, tuple in pairs(opts) do
    local val, kind = unpack(tuple)
    if is_placeholder_group(kind) then
      if val.__name == name then
        return {"circular_self_reference"}
      else
        return {"undefined_group", {missing = val.__name}}
      end
    end
  end
end

local wrap_group_enforce_no_inference = function(name, opts)
  for key, tuple in pairs(opts) do
    local val, kind = unpack(tuple)
    if is_concrete_group(kind) then
      -- WIP for property inference
      -- don't return nil on inferred keys
      --  local check = val[key]
      --  if check == nil then
      --    return resolves_as_error({
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
      return {"inference_disabled", {key = key}}
    end
  end
end

local enforce_no_value_is_group = function(name, opts)
  for key, tuple in pairs(opts) do
    local val, kind = unpack(tuple)
    if is_group(kind) then
      return {"group_value_is_group", {key = key, kind = kind}}
    end
  end
end

-- given a list of validators, execute those validators with group details
-- validators should return true on no error, or false, context on error.
--
-- IMPORTANT: ensure all validators are non-nil, variable is named correctly,
--            is in scope, else ipairs() may skip some or all validations!
--
local enforce = function(validators, group_name, group_options) 
  for i = 1, #validators do
    if type(validators[i]) ~= "function" then
      error("Validate validators malformed, not contiguous or not a function. " ..
            "Likely one of the validators is mis-spelled or not-in-scope (nil)")
    end
  end

  for _, validator in ipairs(validators) do
    local err = validator(group_name, group_options)
    if err then
      local code, context = unpack(err)
      context = context or {}
      context.on = group_name
      return error_for(code, context)
    end
  end
end

-- wrap options in object that either proxies indexes to options
-- or when called, returns the options
local create_direct_group = function(group_name, group_options)
  local enforcements = {
    enforce_definition_is_table,
    enforce_no_protected_keys,
    enforce_no_value_is_group,
    -- these are technically for inference, and no_groups will
    -- fail before these get attempted, while inference is disabled
    wrap_group_enforce_no_placeholders,
    wrap_group_enforce_no_inference,
  }
  local err = enforce(enforcements, group_name, group_options)
  if err then return resolves_as_error(err) end

  local proxied_options = {}
  for key, tuple in pairs(group_options) do
    local val, kind = unpack(tuple)
    -- if is_concrete_group(kind) then
    --   --  -- lush group referenced has key requested,
    --   --  -- so proxy this would-be group's value to the proxy group
    --   --  proxied_options[key] = val[key]
    -- end
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
        __call = resolves_as_error(error_for("group_redefined", {on = group_name}))
      })
    end
  })
end

local enforce_no_circular_self_inherit = function(name, opts)
  local link, kind = unpack(opts[1])
  if name == link.__name then
    return {"circular_self_inherit"}
  end
end

local enforce_no_placeholder_inherit = function(name, opts)
  local link, kind = unpack(opts[1])
  if is_placeholder_group(kind) then
    return {"invalid_parent", {missing = link.__name}}
  end
end

local create_inherit_group = function(group_name, group_options)
  local enforcements = {
    enforce_no_circular_self_inherit,
    enforce_no_placeholder_inherit,
  }
  local err = enforce(enforcements, group_name, group_options)
  if err then return resolves_as_error(err) end

  -- merge values from parent if not present in child
  local merged = {}
  local link, kind = unpack(group_options[1])
  for _, key in ipairs(allowed_option_keys()) do
    local tuple = group_options[key]
    if tuple then
      merged[key] = tuple
    else
      merged[key] = {link[key], type(link[key])}
    end
  end

  return create_direct_group(group_name, merged)
end


local enforce_no_circular_self_link = function(name, opts)
  local link, kind = unpack(opts[1])
  if name == link.__name then
    return {"circular_self_link"}
  end
end

local enforce_no_placeholder_link = function(name, opts)
  local link, kind = unpack(opts[1])
  if is_placeholder_group(kind) then
    return {"invalid_link_name", {link_name = link.__name}}
  end
end

-- wrap link in object that proxies indexes to linked group options
-- or when called, link descriptor
local create_link_group = function(group_name, group_options)
  local enforcements = {
    enforce_no_circular_self_link,
    enforce_no_placeholder_link
  }
  local err = enforce(enforcements, group_name, group_options)
  if err then return resolves_as_error(err) end

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

local create_group = function(group_type, group_name, group_options)
  if group_type == "group" then return create_direct_group(group_name, group_options) end
  if group_type == "inherit" then return create_inherit_group(group_name, group_options) end
  if group_type == "link" then return create_link_group(group_name, group_options) end
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

      local define_group = function(group_placeholder, group_def)

        -- smoke test the basic given properties, if these fail then
        -- nothing beyond here is worth attempting.
        local enforcements = {
          enforce_generic_group_name,
          enforce_generic_definition_type,
          -- kind of awkward to put this validation here, since
          -- it's more specific to inherit and link, but we also
          -- need to fail before attempting to detect the group type.
          -- for now it happens here.
          enforce_generic_one_parent,
        }
        local err = enforce(enforcements, group_name, group_def)
        if err then return resolves_as_error(err) end

        local group_type = infer_group_type(group_def)
        -- not implemented, validatins done in wrap_<type>
        -- local _, err = enforce_group_type(type, group_def)

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

        -- inherit and link both should have a [1] key, but we keep out out of
        -- the allowed options check for ease of use elsewhere.
        if group_def[1] and (group_type == "inherit" or group_type == "link") then
          local val = group_def[1]
          local is_group = group_lookup[val]
          local tuple = {val, is_group and val.__type or type(val)}
          protected[1] = tuple
        end

        -- wrap group in group or link handler
        local group, err = create_group(group_type, group_name, protected)
        if err then
          -- TODO: this could be nicer, technically we should fail before
          --       its possible to get fail group_type inference but ...
          error("Unknown group type? " .. err)
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

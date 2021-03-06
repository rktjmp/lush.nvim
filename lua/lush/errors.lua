local parser = {}

local known_codes = {
    invalid_group_options = "invalid_group_options",
    circular_self_link = "circular_self_link",
    invalid_link_name = "invalid_link_name",
    defintion_must_be_table = "defintion_must_be_table",
    reserved_keyword = "reserved_keyword",
    undefined_group = "undefined_group",
    inference_disabled = "inference_disabled",
    group_redefined = "group_redefined",
    circular_self_inherit = "circular_self_inherit",
    invalid_parent = "invalid_parent",
    too_many_parents = "too_many_parents",
    group_value_is_group = "group_value_is_group",
    malformed_lush_spec = "malformed_lush_spec",
    malformed_lush_spec_options = "malformed_lush_spec_options",
    malformed_lush_spec_extends_option = "malformed_lush_spec_extends_option",
    invalid_group_name = "invalid_group_name",
    could_not_infer_group_type = "could_not_infer_group_type",
    target_not_lush_type = "target_not_lush_type",
}

local message_for_code = function(code)
  local message_map = {
    could_not_infer_group_type = function(context)
      return "Could not infer group type: " .. context.on
    end,
    invalid_group_options = function(context)
      return "Group defition must be a table"
    end,
    circular_self_link = function(context)
      return "Attempt to link self"
    end,
    invalid_link_name = function(context)
      return "Linked group '" .. context.link_name .. "' was never defined, " ..
              "or was not defined before use."
    end,
    defintion_must_be_table = function(context)
      return "Options for " .. context.on .. " was " ..
             context.type .. " but must be table."
    end,
    reserved_keyword = function(context)
      return "Invalid key, __name is reserved"
    end,
    undefined_group = function(context)
      return "Attempt to reference group " .. context.missing ..
            " as value, but group isn't defined before " .. context.on
    end,
    inference_disabled = function(context)
      return "Inference feature disabled"
    end,
    group_redefined = function(context)
      return "Attempted to redefine group: " .. context.on
    end,
    circular_self_inherit = function(context)
      return "Attempted to inherit from self"
    end,
    invalid_parent = function(context)
      return "Parent group '" .. context.missing .. "' was never defined, " ..
             "or was not defined before use."
    end,
    too_many_parents = function(context)
      return "Group " .. context.on .. " tries to inherit from too many parents"
    end,
    group_value_is_group = function(context)
      return "Group " .. context.on .. "." .. context.key .. " must be a "..
             "value, not a group"
    end,
    malformed_lush_spec = function(context)
      return "Malformed lush-spec, unrecoverable"
    end,
    target_not_lush_type = function(context)
      return "Target in '" .. context.on .. "' not a lush type, was '" .. context.type .. "'"
    end,
    malformed_lush_spec_options = function(context)
      return "Malformed lush-spec options, unrecoverable"
    end,
    malformed_lush_spec_extends_option = function(context)
      return "Malformed lush-spec extends option, must be ordered list of parsed lush specs, " ..
             "was '" .. context.type .. "', unrecoverable"
    end,
    invalid_group_name = function(context)
      return "Invalid group name '" .. context.on .. "', names must " ..
              "begin with a letter and may not be " ..
              "ALL, NONE, ALLBUT, contains or contained."
    end
  }

  local message_fn = message_map[code]
  return message_fn or function() return "No message avaliable" end
end


-- TODO we can actually reduce the metaprogramming here, just have to shuffle
--      the known code + messages into a proper format, then just rely on the 
--      metaprograming to alert on unknown errors
parser.generate_for_code = setmetatable({}, {
  __index = function(_, code)
    -- check error code is known, report as hard stop if it's not
    local err = known_codes[code]
    if not err then error("Unknown code: " .. code) end


    return function(context)
      return {
        on = context.on,
        msg = message_for_code(code)(context),
        code = code,
      }
    end
  end
})

return {
  parser = parser
}

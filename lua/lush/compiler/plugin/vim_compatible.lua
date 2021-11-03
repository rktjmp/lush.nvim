-- deprecated in favor of build?
-- local value_or_NONE = require("lush.compiler.plugin.utils").value_or_NONE

-- local vim_compatible = {
--   name = "lush vim-compatible",
--   make_group = function(group_name, group_table, current_rule, entire_spec)
--     -- vim cant handle blend values
--     local modified_rule
--     modified_rule = string.gsub(current_rule, "blend=NONE", "")
--     modified_rule = string.gsub(modified_rule, "blend=%d+", "")

--     -- vim also handles gui values differently
--     if current_rule.gui then
--       modified_rule = modified_rule .. " cterm=" .. value_or_NONE(current_rule.gui)
--     end
--     return modified_rule
--   end,
--   make_link = function(group_name, target_group_name, current_rule, entire_spec) 
--     return current_rule
--   end
-- }

-- return vim_compatible

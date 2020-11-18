local api = vim.api
local hsl = require('lush.hsl')
local lush = require('lush')

local vt_group_ns = api.nvim_create_namespace("lushify_group")
local vt_hsl_ns = api.nvim_create_namespace("lushify_hsl")

-- must define up here since named_hex_highlight_groups is used in a
-- non mod function TODO adjust named_hex_highlight_groups
local M = {}
M.named_hex_highlight_groups = {}

-- Given a line, find any highlight group definitions and color them
-- looks for "   Normal {..."
-- Has potential for false positives, but the negative effect is pretty low
local function set_highlight_groups_on_line(buf, line, line_num)
  -- more generous, must match something like 'Group {'
  local group = string.match(line, "%s-(%a[%a%d_]-)%s-{")
  if group then
    -- technically, find matches the first occurance in line, but this should
    -- always be our group name, so it's ok
    local hs, he = string.find(line, group)
    api.nvim_buf_add_highlight(buf, vt_group_ns, group, line_num, hs - 1, he)
  end
end

-- converts a "hsl(n, n, n)" string to a color
-- (n, n, n) -> hsl
local function hsl_hsl_call_to_color(hsl_hsl_str)
  local h, s, l = string.match(hsl_hsl_str,
                               "hsl%(%s-(%d+)%s-,%s-(%d+)%s-,%s-(%d+)%s-%)")
  return hsl(tonumber(h), tonumber(s), tonumber(l))
end

-- converts a "hsl(hex_str)" string to a color
-- string -> hls
local function hsl_hex_call_to_color(hsl_hex_str)
  local hex_pat = string.rep("[0-9abcdefABCDEF]", 6)
  local hex = string.match(hsl_hex_str,
                          "hsl%([\"'](#"..hex_pat..")[\"']%)")
  return hsl(hex)
end

-- hsl -> string
local function create_highlght_group_name_for_color(color)
  -- substring color from #000000 to 000000
  return "lushify_" .. string.sub(tostring(color), 2)
end

-- given a color, greates a vim highlight group that has that color
-- as the background, and an appropriately readable forground
-- color -> nil
local function create_highlight_group_for_color(color)
  local group_name = create_highlght_group_name_for_color(color)
  -- FIXME: M.named_hex_highlight_groups is a hack
  -- FIXME: also not much error protection going on
  if not M.named_hex_highlight_groups[group_name] then
    M.named_hex_highlight_groups[group_name] = color
    local bg, fg = color, color
    -- make it readable
    fg = bg.l > 50 and fg.lightness(0) or fg.lightness(100)
    -- define the highlight group
    api.nvim_command("highlight! " ..
                      group_name ..
                      " guibg=" .. bg ..
                      " guifg=" .. fg)
  end
end

-- reduce function, matches contains all matches found in str
-- (string, number, table) -> table
local function find_all_hsl_in_str(str, read_head, matches)
  -- setup
  local hsl_pat = "(hsl%(%s-%d+%s-,%s-%d+%s-,%s-%d+%s-%))"
  local hex_chs = string.rep("[0-9abcdefABCDEF]", 6)
  local hex_pat = "(hsl%([\"']#"..hex_chs.."[\"']%))"

  -- check line for match with either colour type
  local hsl_fs, hsl_fe = string.find(str, hsl_pat)
  local hex_fs, hex_fe = string.find(str, hex_pat)
  local fs, fe, type

  -- set fs depending on match success (future ops are type independent)
  if hsl_fs then
    fs, fe = hsl_fs, hsl_fe
    type = "hsl"
  elseif hex_fs then
    fs, fe = hex_fs, hex_fe
    type = "hex"
  end

  -- match'd either colour type, save the call and where it is in the line
  if fs then
    -- make color
    local hsl_call = string.sub(str, fs, fe)
    local color = type == "hsl" and
                  hsl_hsl_call_to_color(hsl_call) or
                  hsl_hex_call_to_color(hsl_call)

    -- save color
    local match = {
      color = color,
      from = read_head + fs,
      to = read_head + fe,
    }
    table.insert(matches, match)

    -- inspect rest of string
    read_head = read_head + fe - 1
    str = string.sub(str, fe)
    find_all_hsl_in_str(str, read_head, matches)
  end

  -- no match ahead, return all matches, stop looking
  return matches
end

-- finds all hsl() calls on a line and applies suitable highlighting
-- (number, string, number) -> nil
local function set_highlight_hsl_on_line(buf, line, line_num)
  local colors = find_all_hsl_in_str(line, 0, {})

  -- apply any colors we found
  if #colors > 0 then
    for _, match in ipairs(colors) do
      local color = match.color

      create_highlight_group_for_color(color)

      local group_name = create_highlght_group_name_for_color(color)
      local hi_s, hi_e = match.from, match.to

      api.nvim_buf_add_highlight(buf, vt_hsl_ns,
                                 group_name, line_num,
                                 hi_s - 1, hi_e) -- -1 for api-indexing
    end
  end
end

-- passes entire contents of buffer to lua interpreter
-- may print error if one occurs
-- (number) -> nil
local function eval_buffer(buf)
  buf = buf or 0
  print("") -- TODO clear any messages (not great, may clobber other tools)

  -- name used for error reporting
  local buf_name = api.nvim_buf_get_name(buf)

  local all_buf_lines = api.nvim_buf_get_lines(buf, 0, -1, true)

  -- pcall:      true, return_val or
  --             false, error_caught
  --
  -- loadstring: function or
  --             nil, error
  --
  -- Loadstring can still "fail" on malformed lua, it will only
  -- return errors that occur in the *code when executed*, which
  -- is why we wrap it in a pcall (else the error propagates up to vim)
  local eval_success, eval_value = pcall(function()
    local code = table.concat(all_buf_lines, "\n")
    local fn, load_error = loadstring(code, "lush.ify.eval_buffer")
    -- bubble error up
    if load_error then error(load_error, 2) end
    return fn()
  end)

  if eval_success then
    -- if we eval'd ok, we have a theme to apply, we can actually still
    -- error here, if the actual spec is invalid once executed
    -- (right now we just know it's vaguely valid lua)
    eval_success, eval_value = pcall(function()
      return lush.apply(lush.compile(eval_value, {force_clean = true}))
    end)
  end

  -- this may catch either pcall's errors
  if not eval_success then
    -- eval failed, so try to output a descriptive reason
    -- format error to be relative to the hot reloaded file
    eval_value = string.gsub(eval_value, "^%[string .+%]", buf_name)
    local msg = "Lushify hot reload did not apply: " .. eval_value
    print(msg)
    -- if a error message wraps in the command output window, the
    -- user is prompted to "press enter or type to continue", which is
    -- pretty annoying for a real time update, so we'll just print
    -- instead, which doesn't get the pretty colouring but it's less
    -- frustrating to actually use.
    -- local cmd = "echohl WarningMsg | echo \"" ..
    --             msg ..
    --             "\" | echohl None"
    -- vim.api.nvim_command(cmd)
  end

  -- even if the eval failed, we can still apply hsl() calls
  -- and GroupName highlighting to lines in the file.
  M.named_hex_highlight_groups = {}
  for i, line in ipairs(all_buf_lines) do
    api.nvim_buf_clear_namespace(buf, vt_group_ns, i, i + 1)
    set_highlight_groups_on_line(buf, line, i - 1)
    set_highlight_hsl_on_line(buf, line, i - 1)
  end
end

M.real_time_eval = function(buf)
  buf = buf or 0
  -- bang the buffer on first call
  eval_buffer(0)
  -- then setup a re-eval on any changes
  api.nvim_buf_attach(buf, true, {
    on_lines = function()
      -- we actually don't care about which lines changed, or anything
      -- just re-eval the whole buffer wholesale.
      eval_buffer(buf)
      -- remain attached
      return false
    end
  })
end

setmetatable(M, {
  __call = function()
    -- real_time_eval evaluates the entire buffer, and lush.apply() will clear
    -- any highlighting, which means any previous hsl() call groups are removed.
    --
    -- So for now (?) we *must* re-apply those hsl() colours again in real_time_eval.
    -- So the previous buffer attachment -> inspect only changed isn't useful.
    --
    -- (One fix might be to pass an env to loadstring (possible?) that disables
    -- clearing?)
    --
    -- So far the performance cost seems near to zero (?!),
    -- so perhaps this is fine.
    --
    -- Ideally, real_time_eval wouldn't just re-eval the whole file, but would be
    -- spec-aware and have a running "current spec" in memory that it patches
    -- and applies. Not sure how resilliant this would be though, through user
    -- pastes, etc. If the spec was in it's own file, it would be more possible
    -- since we'd know that any line is a 1:1 match for a spec line, right now a
    -- change would have to be fake-parsed and we'd have to be watching for
    -- changes only inside the spec line range which while possible, just feels
    -- like a hack.
    --
    -- And all that seems like premature opitmisation anyway, since the
    -- performance cost is so low.
    M.real_time_eval(0)
  end
})

return M

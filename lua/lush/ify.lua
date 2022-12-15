local api = vim.api
local uv = vim.loop
local hsl = require('lush.vivid.hsl.type')
local hsluv = require('lush.vivid.hsluv.type')
local lush = require('lush')
local unpack = unpack or table.unpack

local hl_group_ns = api.nvim_create_namespace("lushify_group")
local hl_vivid_call_ns = api.nvim_create_namespace("lushify_vivid")

local named_hex_highlight_groups_cache ={}

-- Given a line, find any highlight group definitions and color them
-- looks for "   Normal {..."
-- Note: This *does* match commented out lines, which is a good thing since
--       it lets us show "default" highlights on groups. This does give the
--       potential for false positives but the negative side effect is pretty
--       low impact.
local function set_highlight_groups_on_line(buf, line, line_num)
  local group =
      string.match(line, "%s-(%a[%a%d_]-)%s-{") or
      string.match(line, [[%s-(sym%(?["'][%a%d%.@]+["']%)?)%s-{]])

  if group then
    -- technically, find matches the first occurance in line, but this should
    -- always be our group name, so it's ok
    -- we want to highlight the sym() call if it's there, but the group name is actually
    -- the argument.
    local group_name = string.match(group, [[sym%(?["']([%a%d%.@]+)["']%)?]]) or group
    local hs, he = string.find(line, group, 1, true)
    api.nvim_buf_add_highlight(buf, hl_group_ns, group_name, line_num, hs - 1, he)
  end
end

-- build vaild hex chars x 6
local re_hex_chars = string.rep("[0-9abcdefABCDEF]", 6)
local re_hex_pat = "#"..re_hex_chars
-- matches "#NNNNNN"
local re_hex_arg_pat = "%s-[\"']("..re_hex_pat..")[\"']"
-- mathes "h, s, l"
local re_h_s_l_args_pat = "%s-(%d+)%s-,%s-(%d+)%s-,%s-(%d+)%s-"

local re_hsl_h_s_l_call_pat = "hsl%("..re_h_s_l_args_pat.."%)"
local re_hsl_hex_call_pat = "hsl%(?"..re_hex_arg_pat.."%)?"

local re_hsluv_h_s_l_call_pat = "hsluv%("..re_h_s_l_args_pat.."%)"
local re_hsluv_hex_call_pat = "hsluv%(?"..re_hex_arg_pat.."%)?"

-- converts a "hsl(n, n, n)" string to a color
local function hsl_h_s_l_call_to_color(hsl_hsl_str)
  local h, s, l = string.match(hsl_hsl_str,"hsl%("..re_h_s_l_args_pat.."%)")
  return hsl(tonumber(h), tonumber(s), tonumber(l))
end

-- converts a "hsl(hex_str)" string to a color
local function hsl_hex_call_to_color(hsl_hex_str)
  local hex = string.match(hsl_hex_str, "hsl%(?"..re_hex_arg_pat.."%)?")
  return hsl(hex)
end

-- converts a "hsluv(n, n, n)" string to a color
local function hsluv_h_s_l_call_to_color(hsluv_hsluv_str)
  local h, s, l = string.match(hsluv_hsluv_str, "hsluv%("..re_h_s_l_args_pat.."%)")
  return hsluv(tonumber(h), tonumber(s), tonumber(l))
end

-- converts a "hsluv(hex_str)" string to a color
local function hsluv_hex_call_to_color(hsluv_hex_str)
  local hex = string.match(hsluv_hex_str, "hsluv%(?"..re_hex_arg_pat.."%)?")
  return hsluv(hex)
end

-- hsl/hsluv -> string
local function create_highlght_group_name_for_color(color)
  -- substring color from #000000 to 000000
  return "lushify_" .. string.sub(tostring(color), 2)
end

-- given a color, greates a vim highlight group that has that color
-- as the background, and an appropriately readable forground
-- color -> nil
local function create_highlight_group_for_color(color, cache)
  local group_name = create_highlght_group_name_for_color(color)
  if not cache[group_name] then
    cache[group_name] = color
    -- define the highlight group
    api.nvim_command("highlight! " ..
                      group_name ..
                      " guibg=" .. color ..
                      " guifg=" .. color.readable())
  end
end

local function find_all(str, pat)
  local read_head = 1
  return function()
    local substr = string.sub(str, read_head)
    local results = {string.find(substr, pat)}
    if #results > 0 then
      local fs = read_head + table.remove(results, 1) - 1 -- index at 1 garbage
      local fe = read_head + table.remove(results, 1)
      local matches = results
      read_head = fe + 1
      return fs, fe, matches
    end
    return nil
  end
end

-- finds all hsl() calls on a line and applies suitable highlighting
-- (number, string, number) -> nil
local function set_highlight_vivid_calls_on_line(buf, line, line_num)
  -- find hsl(...) and hsluv(...) strings. These may not always be valid
  -- calls (i.e it matches hsl(garbage)) but we act greedy at first
  local calls = {}
  local call_patterns = {
    "(hsl%b())", "(hsl%s*%b'')", '(hsl%s*%b"")',
    "(hsluv%b())", "(hsluv%s*%b'')", '(hsluv%s*%b"")'
  }
  for _, pattern in pairs(call_patterns) do
    for s, e, m in find_all(line, pattern) do
      m = m[1]
      table.insert(calls, {s, e, m})
    end
  end

  -- attempt to turn call strings into real colors by checking if it's
  -- a vaild call, and calling the desired function if so
  local call_pat_to_call_fn = {
    {re_hsl_h_s_l_call_pat, hsl_h_s_l_call_to_color},
    {re_hsl_hex_call_pat, hsl_hex_call_to_color},
    {re_hsluv_h_s_l_call_pat, hsluv_h_s_l_call_to_color},
    {re_hsluv_hex_call_pat, hsluv_hex_call_to_color}
  }
  local colors = {}
  for _, call in pairs(calls) do
    local s, e, call_string = unpack(call)
    for _, pat_fn in ipairs(call_pat_to_call_fn) do
      local pat = pat_fn[1]
      local fn = pat_fn[2]
      if string.match(call_string, pat) then
        table.insert(colors, {
          from = s,
          to = e,
          color = fn(call_string)
        })
        break
      end
    end
  end

  -- apply any colors we found
  if #colors > 0 then
    for _, match in ipairs(colors) do
      local color = match.color

      create_highlight_group_for_color(color, named_hex_highlight_groups_cache)

      local group_name = create_highlght_group_name_for_color(color)
      local hi_s, hi_e = match.from, match.to

      api.nvim_buf_add_highlight(buf, hl_vivid_call_ns,
                                 group_name, line_num,
                                 hi_s - 1, hi_e -1) -- -1 for api-indexing
    end
  end
end

-- Errors can occur in two "spaces", lua-space and lush-space
-- lush-space errors are things that are spec dependent, bad definitions,
-- invalid groups, etc.
-- lua-space errors can be anything, mis-spelt variables, nil indexing, *vim errors*.
-- Since they can happen in intermingled contexts, we have a unified handler that
-- can be called from both stages (loadstring and apply).
local print_error = function(err)
  -- table implies (hopefully!) it's a lush error
  if type(err) == "table" then
    local msg = "Parser Error (" .. err.code .. "): " .. err.on ..
                " -> " .. err.msg
    print(msg)
  else
    -- else it's likely another library or plain lua error
    err = string.gsub(err, "^%[string .+%]:", 'line ') -- strip our loadstring name, leave line number
    local msg = "Lush.ify: Could not parse buffer due to Lua error: " .. err
    print(msg)
  end
end

-- passes entire contents of buffer to lua interpreter
-- may print error if one occurs
-- (number) -> nil

local function eval_buffer(buf)
  buf = buf or 0
  local did_apply = false

  -- local a_time = vim.loop.hrtime()

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
    -- local a = vim.loop.hrtime()
    local fn, load_error = loadstring(code, "lush.ify.eval_buffer")
    --local b = vim.loop.hrtime()
    -- print(b - a / 1000000)
    -- bubble error up
    if load_error then error(load_error, 2) end
    return fn()
  end)

  if not eval_success then
    print_error(eval_value)
    did_apply = false
  end

  if eval_success then
    -- if we eval'd ok, we have a theme to apply, we can actually still
    -- error here, if the actual spec is invalid once executed
    -- (right now we just know it's vaguely valid lua)
    local apply_success, apply_value = pcall(function()
      return lush.apply(lush.compile(eval_value), {force_clean = true})
    end)
    if not apply_success then
      print_error(apply_value)
      did_apply = false
      -- if a error message wraps in the command output window, the
      -- user is prompted to "press enter or type to continue", which is
      -- pretty annoying for a real time update, so we'll just print
      -- instead, which doesn't get the pretty colouring but it's less
      -- frustrating to actually use.
      -- local cmd = "echohl WarningMsg | echo \"" ..
      --             msg ..
      --             "\" | echohl None"
      -- vim.api.nvim_command(cmd)
    else
      -- local b_time = vim.loop.hrtime()
      -- local ms = ((b_time- a_time)/ 100000) -- leave extra sig figure
      -- ms = math.ceil(ms - 0.5)
      -- ms = ms / 10
      -- print("Lush.ify applied successfully in " .. ms .. "ms")
      --
      -- If you set ModeMsg, vim will clear the output line, it seems.
      -- Which makes the above unreliable, so instead of providing an
      -- so instead we will just clear any previous errors that might
      -- hang around.
      print(" ") -- clear error
      did_apply = true
      vim.api.nvim_exec_autocmds("ColorScheme", {})
    end
  end

  -- TODO: Can return to just applying this in on_lines
  --
  -- even if the eval failed, we can still apply hsl() calls
  -- and GroupName highlighting to lines in the file.
  named_hex_highlight_groups_cache = {}
  for i, line in ipairs(all_buf_lines) do
    api.nvim_buf_clear_namespace(buf, hl_group_ns, i, i + 1)
    api.nvim_buf_clear_namespace(buf, hl_vivid_call_ns, i, i + 1)
    set_highlight_groups_on_line(buf, line, i - 1)
    set_highlight_vivid_calls_on_line(buf, line, i - 1)
  end

  return did_apply
end

local M = {}

M.setup_realtime_eval = function(buf, options)
  buf = buf or 0

  -- on_lines can be called multiple times per ms (according to uv timers,
  -- which are some what loose). We will perform a minor debounce, so if a user
  -- is holding down a letter (or can type *really fast*, or maybe using a
  -- macro or pasting into term or ...), we don't try to re-eval excessively.
  --
  -- Additionally, if the last two attemps to eval the buffer have failed,
  -- we will debounce with a larger window, this limits some over-eager
  -- error printing which may degrade performance depending on the term and
  -- machine.
  --
  -- We allow for "last two" to provide minor grace if a user goes from
  -- `hsl(1` to `hsl(` which would error, but they are likley to repair the
  -- error in the next stroke.
  --
  -- Note: Deboucing could be considered 'cumulative', new events will
  --       continue to "push the debounce" until events stop occuring.

  -- normally we debounce by this much
  local natural_timeout = options.natural_timeout or 25
  -- but if we've seen enough errors, debounce by this much
  local error_timeout = options.error_timeout or 300

  if type(natural_timeout) ~= "number" or
     type(error_timeout) ~= "number" or
     natural_timeout <= 0 or
     error_timeout <= 0 then
     error("lush.ify natural_timeout and error_timeout must be positive numbers", 0)
   end

  local defer_timer = nil

  -- tracks last N runs on a N-size stack,
  -- push records a run
  -- had_errors tells us if any runs on the stack had errors
  local history
  history = {
    true, true,
    push = function(val)
      history[2] = history[1]
      history[1] = val
    end,
    infer_timeout = function()
      if not history[1] and not history[2] then
        -- both recorded runs were false -> error occured
        return error_timeout
      else
        return natural_timeout
      end
    end,
  }

  -- bang the buffer on first call
  eval_buffer(buf)
  -- then setup a re-eval on any changes
  api.nvim_buf_attach(buf, true, {
    on_lines = function()
      local defer_timer_callback = function()
        if defer_timer then
          uv.close(defer_timer)
          defer_timer = nil
        end
        vim.schedule(function()
          local success = eval_buffer(buf)
          history.push(success)
        end)
      end

      -- cancel any standing timer, we will replace it
      if defer_timer then
        uv.timer_stop(defer_timer)
        uv.close(defer_timer)
        defer_timer = nil
      end

      defer_timer = uv.new_timer()
      local defer_timeout = history.infer_timeout()
      uv.timer_start(defer_timer, defer_timeout, 0, defer_timer_callback)

      -- remain attached
      return false
    end
  })
end

setmetatable(M, {
  __call = function(_, options)
    options = options or {}

    -- setup_realtime_eval evaluates the entire buffer, and lush.apply() will
    -- clear any highlighting, which means any previous hsl() call groups are
    -- removed.
    --
    -- So for now (?) we *must* re-apply those hsl() colours again in setup_realtime_eval.
    -- So the previous buffer attachment -> inspect only changed isn't useful.
    --
    -- (One fix might be to pass an env to loadstring (possible?) that disables
    -- clearing?)
    --
    -- So far the performance cost seems near to zero (?!),
    -- so perhaps this is fine.
    --
    -- Ideally, setup_realtime_eval wouldn't just re-eval the whole file, but
    -- would be spec-aware and have a running "current spec" in memory that it
    -- patches and applies. Not sure how resilliant this would be though,
    -- through user pastes, etc. If the spec was in it's own file, it would be
    -- more possible since we'd know that any line is a 1:1 match for a spec
    -- line, right now a change would have to be fake-parsed and we'd have to
    -- be watching for changes only inside the spec line range which while
    -- possible, just feels like a hack.
    --
    -- 2020/11/22 - time for loadstring is 5ms, time for apply is between
    --              very low 0-2ms and long 10ms?, seemingly depending on how
    --              vim feels. This difference is observed over the same spec
    --              with no changes. Having an in-memory spec is unlikely to
    --              aid anything. the real bottle neck is probably vim itself.
    --
    -- And all that seems like premature opitmisation anyway, since the
    -- performance cost is so low.
    M.setup_realtime_eval(0, options)
  end
})

return M

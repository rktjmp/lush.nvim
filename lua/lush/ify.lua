local api = vim.api
local uv = vim.loop
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
                          "hsl%(?%s-[\"'](#"..hex_pat..")[\"']%)?")
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
  local hex_pat = "(hsl%(?%s-[\"']#"..hex_chs.."[\"']%)?)"

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
      return lush.apply(lush.compile(eval_value, {force_clean = true}))
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
    end
  end

  -- TODO: Can return to just applying this in on_lines
  --
  -- even if the eval failed, we can still apply hsl() calls
  -- and GroupName highlighting to lines in the file.
  M.named_hex_highlight_groups = {}
  for i, line in ipairs(all_buf_lines) do
    api.nvim_buf_clear_namespace(buf, vt_group_ns, i, i + 1)
    api.nvim_buf_clear_namespace(buf, vt_hsl_ns, i, i + 1)
    set_highlight_groups_on_line(buf, line, i - 1)
    set_highlight_hsl_on_line(buf, line, i - 1)
  end

  return did_apply
end

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

  -- the uv timer
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
  eval_buffer(0)
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
    --              aid anything. the real bottle neck is vim itself.
    --
    -- And all that seems like premature opitmisation anyway, since the
    -- performance cost is so low.
    M.setup_realtime_eval(0, options)
  end
})

return M

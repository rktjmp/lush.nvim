local api = vim.api
local hsl = require('lush.hsl')

local vt_group_ns = api.nvim_create_namespace("lushify_group")
local vt_hsl_ns = api.nvim_create_namespace("lushify_hsl")

local function set_highlight_groups_on_line(buf, line, line_num)
  -- more conservative, all on one line matcher
  -- local group = string.match(line, "%s-(%a[%a%d_]-)%s-{.*},*")
  -- more generous, must match something like 'Group {'
  local group = string.match(line, "%s-(%a[%a%d_]-)%s-{")
  if group then
    -- technically, find matches the first occurance in line, but this will
    -- always be our group name, so it's ok
    local hs, he = string.find(line, group)
    api.nvim_buf_clear_namespace(buf, vt_group_ns, line_num, line_num + 1)
    api.nvim_buf_add_highlight(buf, vt_group_ns, group, line_num, hs - 1, he)
  end
end

local M = {}

local function hsl_hsl_call_to_color(hsl_hsl_str)
  local h, s, l = string.match(hsl_hsl_str,
                               "hsl%(%s-(%d+)%s-,%s-(%d+)%s-,%s-(%d+)%s-%)")
  return hsl(tonumber(h), tonumber(s), tonumber(l))
end

local function hsl_hex_call_to_color(hsl_hex_str)
  local hex_pat = string.rep("[0-9abcdefABCDEF]", 6)
  local hex = string.match(hsl_hex_str,
                          "hsl%([\"'](#"..hex_pat..")[\"']%)")
  return hsl(hex)
end

local function set_highlight_hsl_on_line(buf, line, line_num)
  local hsl_hsl_match = string.match(line, "(hsl%(%s-%d+%s-,%s-%d+%s-,%s-%d+%s-%))")
  local hex_pat = string.rep("[0-9abcdefABCDEF]", 6)
  local hsl_hex_match = string.match(line,
                                     "(hsl%([\"']#"..hex_pat.."[\"']%))")
  local color
  local highlight_pos_str
  if hsl_hsl_match then
    color = hsl_hsl_call_to_color(hsl_hsl_match)
    highlight_pos_str = hsl_hsl_match
  elseif hsl_hex_match then
    color = hsl_hex_call_to_color(hsl_hex_match)
    highlight_pos_str = hsl_hex_match
  end
  if color then
    -- substring color from #000000 to 000000
    local group_name = "lushify_" .. string.sub(tostring(color), 2)
    -- FIXME: M.seen_colors is a hack
    -- FIXME: also not much error protection going on
    if not M.seen_colors[group_name] then
      local bg, fg = color, color
      if bg.l > 50 then
        fg = fg.lightness(0)
      else
        fg = fg.lightness(100)
      end

      api.nvim_command("highlight! " .. group_name .. " guibg=" .. bg .. " guifg=" .. fg)
    end

    local hs, he = string.find(line, highlight_pos_str, 1, true)
    api.nvim_buf_clear_namespace(buf, vt_hsl_ns, line_num, line_num + 1)
    api.nvim_buf_add_highlight(buf, vt_hsl_ns, group_name, line_num, hs - 1, he)
  end
end

M.current_attach_id = 0
M.seen_colors = {}

M.attach_to_buffer = function(buf)
  buf = buf or 0

  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
  for i, line in ipairs(lines) do
    set_highlight_groups_on_line(buf, line, i - 1)
    set_highlight_hsl_on_line(buf, line, i - 1)
  end

  M.current_attach_id = M.current_attach_id + 1
  M.seen_colors = {}
  local closure = function()
    local attach_id = M.current_attach_id
     api.nvim_buf_attach(buf, true, {
      on_lines = function(_, buf, _changed_tick, first_line, _, last_line)
        -- check between first and last line for a group defintion
        local lines = api.nvim_buf_get_lines(buf, first_line, last_line, true)
        for i, line in ipairs(lines) do
          set_highlight_groups_on_line(buf, line, first_line + i - 1)
          set_highlight_hsl_on_line(buf, line, first_line + i - 1)
        end

        -- if we call attach_to_buffer() again, we want to detach any existing
        -- attachments. There isn't a super clean way to "get attachments for
        -- buffer" or similar right now, and tracking attached(bufn) in an list
        -- is also problematic because re-sourcing your theme tends to clear
        -- any highlighting, so previously seen colors get lost, etc, etc.
        -- Also if we do in-code modification parsing of hsl changes, we need to
        -- track those per buffer.
        --
        -- SO, for now, we say lushify can only attach to one buffer, the last
        -- buffer you called it for. This will generally be acceptable anyway.

        -- return true to detach
        return M.current_attach_id ~= attach_id
      end
    })
  end
  closure()
end

M.as_you_type = function(buf)
  buf = buf or 0
  local buf_name = api.nvim_buf_get_name(buf)

  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
  lines = table.concat(lines, "\n")

  -- pcall: catch error and return status, either:
  --        true, return_val or
  --        false, error_caught
  -- loadstring:
  --            function or
  --            nil, error
  -- Loadstring can still "fail" on malformed lua, it will only
  -- return errors that occur in the *code when executed*, which
  -- is why we wrap it in a pcall (else the error propagates up to vim)
  local success, error = pcall(function()
    local fn, load_error = loadstring(lines, "lush.ify.hot_take")
    -- bubble error up
    if load_error then error(load_error, 2) end
    fn()
  end)

  if not success then
    if error then
      -- format error to be relative to the hot reloaded file
      error = string.gsub(error, "^%[string .+%]", buf_name)
      local msg = "Lushify hot reload did not apply: " .. error
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
  end
end

local call = function()
  M.attach_to_buffer(0)
  -- we reattach on save, because when we source the lush-spec, it will
  -- run "hi clear" which will remove any hsl() definitions, so reattach
  -- to redefine them. The cost is small.
  -- TODO: Worth improving ify reattachment autocommand?
  local autocmds = [[
  augroup LushIfyReloadGroup
  autocmd!
  autocmd TextChanged,TextChangedI <buffer> :lua require('lush.ify').as_you_type(0)
  autocmd BufWritePost <buffer> :luafile <afile>
  autocmd BufWritePost <buffer> :lua require('lush.ify').attach_to_buffer(0)
  augroup END
  ]]
  vim.api.nvim_exec(autocmds, false)
end

setmetatable(M, {
  __call = call
})

return M

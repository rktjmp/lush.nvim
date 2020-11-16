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

M.hottake = function(buf)
  buf = buf or 0
  print("hottake")
  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
  print("call loadstring for " .. #lines .. " lines")
  local a, b = pcall(loadstring(table.concat(lines, "\n"), "lush.ify.hot_take"))
  print(a, b)
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
  autocmd TextChanged,TextChangedI <buffer> :lua require('lush.ify').hottake(0)
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

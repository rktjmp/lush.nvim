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

local function create_highlght_group_name_for_color(color)
  -- substring color from #000000 to 000000
  return "lushify_" .. string.sub(tostring(color), 2)
end

local function create_highlight_group_for_color(color)
  local group_name = create_highlght_group_name_for_color(color)
  -- FIXME: M.seen_colors is a hack
  -- FIXME: also not much error protection going on
  if not M.seen_colors[group_name] then
    local bg, fg = color, color
    fg = bg.l > 50 and fg.lightness(0) or fg.lightness(100)
    api.nvim_command("highlight! " ..
                      group_name ..
                      " guibg=" .. bg ..
                      " guifg=" .. fg)
  end
end

-- reduce function, matches contains all matches found in str
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


local function set_highlight_hsl_on_line(buf, line, line_num)
  local colors = find_all_hsl_in_str(line, 0, {})

  -- always clear current highlights for line
  api.nvim_buf_clear_namespace(buf, vt_hsl_ns, line_num, line_num + 1)

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
  local success, error = pcall(function()
    local code = table.concat(all_buf_lines, "\n")
    local fn, load_error = loadstring(code, "lush.ify.hot_take")
    -- bubble error up
    if load_error then error(load_error, 2) end
    fn()
  end)

  -- highlight any hsl(...) calls
  for i, line in ipairs(all_buf_lines) do
    set_highlight_groups_on_line(buf, line, i - 1)
    set_highlight_hsl_on_line(buf, line, i - 1)
  end

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
  -- OUTDATED, (Posterity?):
  --
  -- we reattach on save, because when we source the lush-spec, it will
  -- run "hi clear" which will remove any hsl() definitions, so reattach
  -- to redefine them. The cost is small.
  --
  -- NEW:
  --
  -- as_you_type evaluates the entire buffer, and lush.apply() will clear
  -- any highlighting, which means any previous hsl() call groups are removed.
  -- So for now (?) we *must* re-apply those hsl() colours again in as_you_type.
  -- So the previous buffer attachment -> inspect only changed isn't useful.
  --
  -- (One fix might be to pass an env to loadstring (possible?) that disables
  -- clearing?)
  --
  -- So far the performance cost seems near to zero (?!), so perhaps this is fine.
  --
  -- Ideally, as_you_type wouldn't just re-eval the whole file, but would be
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

  -- M.attach_to_buffer(0)
  -- autocmd BufWritePost <buffer> :luafile <afile>
  -- autocmd BufWritePost <buffer> :lua require('lush.ify').attach_to_buffer(0)

  -- bang on first load then rely on events
  M.as_you_type(0)
  local autocmds = [[
    augroup LushIfyReloadGroup
    autocmd!
    autocmd TextChanged,TextChangedI <buffer> :lua require('lush.ify').as_you_type(0)
    augroup END
  ]]

  vim.api.nvim_exec(autocmds, false)
end

setmetatable(M, {
  __call = call
})

return M

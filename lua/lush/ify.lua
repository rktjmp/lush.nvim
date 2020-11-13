local api = vim.api
local hsl = require('lush.hsl')

local vt_namespace = api.nvim_create_namespace("lushify")

local function set_highlight_groups_on_line(buf, line, line_num)
  local group = string.match(line, "%s-(%a[%a%d]-)%s-{.*},*")
  if group then
    -- technically, find matches the first occurance in line, but this will
    -- always be our group name, so it's ok
    local hs, he = string.find(line, group)
    api.nvim_buf_clear_namespace(buf, vt_namespace, line_num, line_num + 1)
    api.nvim_buf_add_highlight(buf, vt_namespace, group, line_num, hs - 1, he)
  end
end

local M = {}

local function set_highlight_hsl_on_line(buf, line, line_num)
  local all, h, s, l = string.match(line, "(hsl%(%s-(%d+),%s-(%d+)%s-,%s-(%d+)%s-%))")
  if all and h and s and l then
    -- line has hsl() on it, construct color and group name for color
    local color = hsl(tonumber(h), tonumber(s), tonumber(l))
    -- substring color from #000000 to 000000
    local group_name = "lushify_" .. string.sub(tostring(color), 2)
    -- WARN: M.seen_colors is a hack
    if not M.seen_colors[group_name] then
      local bg, fg = color, color
      if bg.l > 50 then
        fg = fg.lightness(0)
      else
        fg = fg.lightness(100)
      end

      api.nvim_command("highlight! " .. group_name .. " guibg=" .. bg .. " guifg=" .. fg)
    end

    local hs, he = string.find(line, all, 1, true)
    api.nvim_buf_clear_namespace(buf, vt_namespace, line_num, line_num + 1)
    api.nvim_buf_add_highlight(buf, vt_namespace, group_name, line_num, hs - 1, he)
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

return setmetatable(M, {
  __call = function(m)
    M.attach_to_buffer(0)
  end
})

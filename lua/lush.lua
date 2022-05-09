local hsl = require('lush.vivid.hsl.type')
local hsluv = require('lush.vivid.hsluv.type')

local parser = require('lush.parser')
local compiler = require('lush.compiler')

local function merge_default_options(options)
  if not options then
    options = {
      -- default to clean
      force_clean = true
    }
  end
  return options
end

local insert_force_clean = function(compiled_ast)
    local clean = {
      "hi clear",
      "set t_Co=256",
    }
    if vim.g.colors_name then
      -- 'hi clear' will clear g:colors_name, so restore if it existed
      table.insert(clean, "let g:colors_name='" .. vim.g.colors_name.."'")
    end

    for i, c in ipairs(clean) do
      table.insert(compiled_ast, i, c)
    end

    return compiled_ast
end

local M = {}

-- usability binds
M.hsl = hsl
M.hsluv = hsluv
M.ify = function(options)
  -- localise this require so test's don't complain about
  -- missing vim globals, etc
  require('lush.ify')(options)
end

-- spec -> table
M.parse = function(spec, options)
  return parser(spec, options)
end

-- table -> table
M.compile = function(ast, options)
  local compiled = compiler(ast, options)

  if options and options.force_clean then
    compiled = insert_force_clean(compiled)
  end

  return compiled
end

-- keys as seen from:
-- https://github.com/neovim/neovim/blob/6d4180a0d20d0b730b6e64acdac39261f52a9277/src/nvim/highlight.c#L813
-- docs say "like synIDattr" but we don't use "fg#" and we can also send in "link"
M.apply = function(parsed_spec, options)
  -- a parsed spec is actually pretty close to what nvim_set_hl wants, apart
  -- from gui = "bold,..." which is stuck in legacy format. it would be nice to
  -- basically drop that key and just accept anything given in the spec table
  -- (excluding "lush" namespace) and pass that on to nvim_set_hl but that would
  -- be a pretty big breaking change.
  -- We may support both, I guess?
  for group, def in pairs(parsed_spec) do
    if def.link then
      -- links are just links and need no extra work
      vim.api.nvim_set_hl(0, group, {link = def.link})
    else
      -- most keys can be copied 1:1, if present
      local attrs = {
        -- color values
        fg = (def.fg and def.fg.hex),
        bg = (def.bg and def.bg.hex),
        sp = (def.sp and def.sp.hex),
        -- blend is an int value
        blend = def.blend
      }

      -- if gui key is present, split it out to component flags, ideally
      -- we will deprecate this in favour of users simply setting the
      -- keys themeselves.
      if def.gui then
        local gui = string.lower(def.gui)
        attrs.bold = (string.match(gui, "[^%w]?bold[^%w]?") ~= nil)
        attrs.italic = (string.match(gui, "[^%w]?italic[^%w]?") ~= nil)
        attrs.underline = (string.match(gui, "[^%w]?underline[^%w]?") ~= nil)
        attrs.underlineline = (string.match(gui, "[^%w]?underlineline[^%w]?") ~= nil)
        attrs.undercurl = (string.match(gui, "[^%w]?undercurl[^%w]?") ~= nil)
        attrs.underdot = (string.match(gui, "[^%w]?underdot[^%w]?") ~= nil)
        attrs.underdash = (string.match(gui, "[^%w]?underdash[^%w]?") ~= nil)
        attrs.strikethrough = (string.match(gui, "[^%w]?strikethrough[^%w]?") ~= nil)
        attrs.reverse = (string.match(gui, "[^%w]?reverse[^%w]?") ~= nil)
        -- not supported in highlight.c
        -- attrs.inverse = (string.match(gui, "[^%w]?inverse[^%w]?") ~= nil)
        attrs.standout = (string.match(gui, "[^%w]?standout[^%w]?") ~= nil)
        attrs.nocombine = (string.match(gui, "[^%w]?nocombine[^%w]?") ~= nil)
      end
      print(vim.inspect({group, attrs}))
      vim.api.nvim_set_hl(0, group, attrs)
    end
  end
end

M.stringify = function(parsed_spec, options)
  options = merge_default_options(options)
  local compiled = M.compile(parsed_spec, options)
  return table.concat(compiled, '\n')
end

M.export_to_buffer = function(parsed_spec)
  local lines = M.compile(parsed_spec)

  table.insert(lines, 1, "\"Theme built with Lush.nvim, exported at " .. os.date())

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = vim.api.nvim_win_get_width(0) - 2 ,
    height = vim.api.nvim_win_get_height(0) - 2,
    row = 1,
    col = 1,
    style = "minimal",
  })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

M.import = function()
  local importer = require("lush.importer")
  return importer.import()
end

-- given a spec function, generate a parsed spec
-- (spec, table) -> table
local easy_spec = function(spec, options)
  local parsed = M.parse(spec, options)
  -- return parsed spec for use with externals
  return parsed
end

-- given a parsed spec, apply the spec
local easy_parsed = function(parsed_spec, options)
  options = merge_default_options(options)
  M.apply(parsed_spec, options)
  -- return parsed spec for use with externals
  -- TODO: Should easy_parsed return parsed_spec or a different identifier?
  return parsed_spec
end

-- We can call lush in two styles, with the intention of making boilerplate
-- easier. detect_easy is metaprogramed to M.__call.
--
-- lush(function() ... end)
--   -> define a lush spec, returns a parsed spec
--   -> traditionally called in a lua/lush_theme/theme.lua file
--
-- lush({...})
--   -> applying a parsed spec, automatically sets the clear option
--   -> traditionally called in the colors/colors.vim file
--
-- (spec or parsed_spec, table) -> parsed_spec or apply_spec
local function detect_easy(spec_or_parsed, options)
  -- specs are functions
  if type(spec_or_parsed) == "function" then
    local spec = spec_or_parsed
    return easy_spec(spec, options)
  -- parsed specs are tables
  elseif type(spec_or_parsed) == "table" and
         spec_or_parsed.__lush and
         spec_or_parsed.__lush.type == "parsed_lush_spec" then
    local parsed = spec_or_parsed
    return easy_parsed(parsed, options)
  else
    error("lush() supplied incorrect arguments")
  end
end

-- accepts list of parsed specs which it passes to the 'with'd specs
-- under the extends option
-- returns a parsed_lush_spec
M.extends = function(extends_list)
  local with = function(spec, options)
    options = options or {}
    options.extends = extends_list
    return M.parse(spec, options)
  end

  return {
    with = with
  }
end

-- accepts a list of parsed specs, merges them in order
-- (equivilent to extends({...}).with(empty_spec))
-- returns a parsed_lush_spec
M.merge = function(extends_list)
  local options = {
    extends = extends_list
  }

  local empty_spec = function()
    return {}
  end

  return M.parse(empty_spec, options)
end

-- delegate __call to detect_easy for DX QOL.
return setmetatable(M, {
  __call = function(m, ...)
    local fn, opts = ...
    return detect_easy(fn, opts)
  end,
})

describe "lush", ->
  lush = require('lush')
  nvim_command_spy, red, green, blue = nil
  lush_spec = nil

  before_each ->
    vim = {
      api: {
        nvim_command: ->
        nvim_create_buf: ->
        nvim_buf_set_lines: ->
        nvim_win_get_height: -> 30
        nvim_win_get_width: -> 30
        nvim_open_win: ->
      },
      g: {
        colors_name: "a_theme"
      }
    }
    _G.vim = mock(vim)
    red = lush.hsl(0, 100, 50)
    green = lush.hsl(120, 100, 50)
    blue = lush.hsl(240, 100, 50)
    lush_spec = -> {
      Normal { bg: red, fg: blue },
      CursorLine { bg: green, fg: red, gui: "bold" }
      NormalFloat { Normal },
      PmemuSel { blend: 10 }
    }

  it "exports hsl", ->
    assert.not_nil(lush.hsl)
    red = lush.hsl(0, 100, 50)
    assert.not_nil(red)
    assert.equal("#FF0000", red.hex)

  it "exports ify", ->
    assert.is_function(lush.ify)

  describe "() mode", ->
    it "creates scheme when called with spec", ->
      parsed = lush(lush_spec)
      assert.spy(vim.api.nvim_command).was_not_called()
      assert.not_nil(parsed)

    it "applies scheme when called with parsed spec", ->
      parsed = lush(lush_spec)
      assert.spy(vim.api.nvim_command).was_not_called()
      lush(parsed)
      assert.spy(vim.api.nvim_command).was_called()
      assert.spy(vim.api.nvim_command).was_called_with(
        "highlight Normal guifg=#0000FF guibg=#FF0000 guisp=NONE gui=NONE blend=NONE"
      )
      assert.spy(vim.api.nvim_command).was_called_with(
        "highlight PmemuSel guifg=NONE guibg=NONE guisp=NONE gui=NONE blend=10"
      )

    it "applies scheme with default options", ->
      parsed = lush(lush_spec)
      lush(parsed)
      assert.spy(vim.api.nvim_command).was_called_with("hi clear")

    it "applies scheme with provided options", ->
      parsed = lush(lush_spec)
      lush(parsed,{force_clean: false})
      assert.spy(vim.api.nvim_command).was_called()
      assert.spy(vim.api.nvim_command).was_not_called_with("hi clear")

    it "detects poor arguments", ->
      -- obviously wrong
      assert.error(-> lush())
      assert.error(-> lush(10))
      assert.error(-> lush("string"))

      -- less obviously wrong
      e = assert.error(-> lush(->))
      assert.equal("malformed_lush_spec", e.code)
      assert.not.matches("No message avaliable", e.msg)

      e = assert.error(-> lush({}))
      assert.equal("lush() supplied incorrect arguments", e)

  it "can output scheme as text", ->
    -- no options
    parsed = lush(lush_spec)
    text = lush.stringify(parsed)
    assert.is_string(text)
    assert.is_equal(7, select(2, string.gsub(text, '\n', '\n')))
    -- options
    parsed = lush(lush_spec)
    text = lush.stringify(parsed, {force_clean: false})
    assert.is_string(text)
    assert.is_equal(3, select(2, string.gsub(text, '\n', '\n')))
  
  it "is a closure", ->
    math = math
    lush_spec = -> {
      A { bg: math.random(10) }
    }
    parsed = lush(lush_spec)
    assert.is_number(parsed.A.bg)

  it "exposes a manual toolchain", ->
    parsed = lush.parse(lush_spec)
    assert.not_nil(parsed)
    assert.same(parsed, lush(lush_spec))
    compiled = lush.compile(parsed)
    assert.not_nil(compiled)
    assert.same(table.concat(compiled, '\n'), lush.stringify(parsed, {force_clean: false}))

  it "exposes a useful parsed object", ->
    parsed = lush.parse(lush_spec)
    assert.not_nil(parsed.Normal)
    assert.not_nil(parsed.Normal.bg)
    assert.equal(0, parsed.Normal.bg.h)
    assert.equal("#FF0000", tostring(parsed.Normal.bg))

  it "exports to buffer", ->
    parsed = lush.parse(lush_spec)
    lush.export_to_buffer(parsed)
    assert.spy(vim.api.nvim_create_buf).was_called()
    assert.spy(vim.api.nvim_buf_set_lines).was_called()

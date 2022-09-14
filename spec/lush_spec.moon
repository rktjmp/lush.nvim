describe "lush", ->
  lush = require('lush')
  red, green, blue = nil
  lush_spec = nil

  before_each ->
    vim = {
      cmd: ->
      api: {
        nvim_exec: ->
        nvim_create_buf: ->
        nvim_buf_set_lines: ->
        nvim_win_get_height: -> 30
        nvim_win_get_width: -> 30
        nvim_open_win: ->
        nvim_set_hl: ->
        nvim_command: ->
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
      assert.spy(vim.api.nvim_exec).was_not_called()
      assert.spy(vim.api.nvim_set_hl).was_not_called()
      assert.not_nil(parsed)

    it "applies scheme when called with parsed spec", ->
      parsed = lush(lush_spec)
      assert.spy(vim.api.nvim_exec).was_not_called()
      lush(parsed)
      assert.spy(vim.api.nvim_exec).was_called()
      assert.spy(vim.api.nvim_set_hl).was_called_with(0, "Normal", {bg: "#FF0000", fg: "#0000FF"})
      assert.spy(vim.api.nvim_set_hl).was_called_with(0, "NormalFloat", {link: "Normal"})

    it "applies scheme with default options", ->
      parsed = lush(lush_spec)
      lush(parsed)
      assert.spy(vim.api.nvim_exec).was_called_with(
        "highlight clear\nset t_Co=256\nlet g:colors_name='a_theme'",
        false)

    it "applies scheme with provided options", ->
      parsed = lush(lush_spec)
      lush(parsed,{force_clean: false})
      assert.spy(vim.api.nvim_exec).was_not_called()

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

  it "is a closure", ->
    math = math
    lush_spec = -> {
      A { bg: math.random(10) }
    }
    parsed = lush(lush_spec)
    assert.is_number(parsed.A.bg)

  it "exposes a useful parsed object", ->
    parsed = lush.parse(lush_spec)
    assert.not_nil(parsed.Normal)
    assert.not_nil(parsed.Normal.bg)
    assert.equal(0, parsed.Normal.bg.h)
    assert.equal("#FF0000", tostring(parsed.Normal.bg))

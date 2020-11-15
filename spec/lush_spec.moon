describe "lush", ->
  describe "requiring", ->
    it "requires as table", ->
      lush = require('lush')
      assert.is_not_nil(lush.hsl)
      assert.is_not_nil(lush.create)

    pending "can be unpacked", ->
      hsl, lush = require('lush')()
      assert.is_not_nil(module, "module")
      assert.is_not_nil(hsl, "hsl")
      assert.is_not_nil(lush, "lush")

  describe "usage", ->
    lush = require('lush')
    hsl = lush.hsl
    nvim_command_spy, red, green, blue = nil

    before_each ->
      nvim_command_spy = spy.new(->)
      _G.vim = {
        api: {
          nvim_command: nvim_command_spy
        }
        g: {
          colors_name: "a_theme"
        }
      }
      red = hsl(0, 100, 50)

    it "can define colors", ->
      assert.not_nil(red)
      assert.equal("#FF0000", red.hex)

    it "generates a scheme", ->
      scheme = lush.create -> {
        Normal { bg: red, fg: blue },
        CursorLine { bg: green, fg: red, gui: "bold" }
        NormalFloat { Normal }
      }
      assert.not_nil(scheme)

    it "can output scheme as text", ->
      scheme = lush.create -> {
        Normal { bg: red, fg: blue },
        CursorLine { bg: green, fg: red, gui: "bold" }
        NormalFloat { Normal }
      }
      text = lush.stringify(scheme)
      assert.is_string(text)
      assert.is_equal(3, select(2, string.gsub(text, '\n', '\n')))

    it "can apply the scheme", ->
      scheme = lush.create -> {
        Normal { bg: red, fg: blue },
        CursorLine { bg: green, fg: red, gui: "bold" }
        NormalFloat { Normal }
      }
      lush.apply(scheme)
      for _, rule in ipairs(scheme) do
        assert.spy(vim.api.nvim_command).was_called_with(rule)
      assert.is_equal(3, #vim.api.nvim_command.calls)

    it "is needleslly overloaded", ->
      lush = require('lush')
      assert.is_equal(0, #vim.api.nvim_command.calls)
      lush(-> {
        Normal { bg: red, fg: blue },
        CursorLine { bg: green, fg: red, gui: "bold" }
        NormalFloat { Normal }
      }, {force_clean: false})
      assert.is_equal(3, #vim.api.nvim_command.calls)


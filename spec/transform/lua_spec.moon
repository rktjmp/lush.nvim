describe "transforms run.lua", ->
  setup ->
    parse = require('lush.parser')
    hsl = require('lush.hsl')
    ast = parse -> {
      A {fg: hsl(50, 50, 50), gui: "italic", blend: 40 },
      B {A, gui: "italic", blend: 90 },
      AA {bg: "red" },
      C {A}
    }
    package.loaded["theme"] = ast
    _G.vim = {
      inspect: ->
        "inspect mock"
      list_slice: (list, s, e) ->
        [item for item in *list[s,e]]
    }

  teardown ->
    package.loaded["theme"] = nil

  it "returns lua code", ->
    to_lua = require("shipwright.transform.lush.to_lua")
    value = to_lua(require("theme"))
    assert.is.table(value)
    assert.equals([[A = {fg = "#BFAA40", blend = 40, italic = true},]], value[1])
    assert.equals([[C = {link = "A"},]], value[2])
    assert.equals([[AA = {bg = "red"},]], value[3])
    assert.equals([[B = {fg = "#BFAA40", blend = 90, italic = true},]], value[4])

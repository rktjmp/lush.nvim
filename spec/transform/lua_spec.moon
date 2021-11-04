describe "transforms run.lua", ->
  run = require("lush.builder").run

  setup ->
    lua = require("lush.transform.lush_to_lua")
    parse = require('lush.parser')
    ast = parse -> {
      A { gui: "italic", blend: 40 },
      B { gui: "italic", blend: 40 }
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
    value = run(require("theme"), lua)
    assert.is.table(value)

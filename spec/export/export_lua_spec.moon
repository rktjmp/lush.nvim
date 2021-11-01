describe "export.lua", ->
  -- note, "export" is a protected keyword in moonscript
  exporter = require("lush.exporter")
  exp = exporter.export

  setup ->
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
    lua = require("lush.transformer.lua")
    value = exp(require("theme"), lua)
    assert.is.table(value)

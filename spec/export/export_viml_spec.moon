describe "export.viml", ->
  -- note, "export" is a protected keyword in moonscript
  exporter = require("lush.exporter")
  exp = exporter.export

  setup ->
    parse = require('lush.parser')
    ast = parse -> {
      A { gui: "italic", blend: 40 }
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

  it "returns viml", ->
    viml = require("lush.transformer.viml")
    value = exp(require("theme"), viml)
    assert.is.table(value)
    assert.matches("highlight A guifg=NONE guibg=NONE guisp=NONE gui=italic blend=40", value[1])

  it "accepts options", ->
    viml = require("lush.transformer.viml")
    value = exp(require("theme"), {viml, {plugins: require("lush.compiler.plugin.vim_compatible")}})
    assert.is.table(value)
    assert.matches("highlight A guifg=NONE guibg=NONE guisp=NONE gui=italic blend=40", value[1])

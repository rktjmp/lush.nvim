describe "run.vimscript", ->
  setup ->
    parse = require('lush.parser')
    ast = parse -> {
      A { gui: "italic bold", underline: true, blend: 40 }
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

  it "returns vimscript", ->
    vimscript = require("shipwright.transform.lush.to_vimscript")
    value = vimscript(require("theme"))
    assert.is.table(value)
    assert.matches("highlight A guifg=NONE guibg=NONE guisp=NONE blend=40 gui=bold,italic,underline", value[1])

  it "orders the vimscript", ->
    vimscript = require("shipwright.transform.lush.to_vimscript")
    parse = require('lush.parser')
    ast = parse -> {
      Apple { fg: "red", gui: "italic", blend: 40 }, -- first
      Bananna { gui: "italic", blend: 40 }, -- after apple and links
      Strawberry { Apple, gui: "bold"},
      Cat { Apple } -- link, so after apple, after bandana
      Bandana { Apple } -- link, so after apple
    }
    value = vimscript(ast)
    assert.match("highlight Apple", value[1])
    assert.match("link Bandana Apple", value[2])
    assert.match("link Cat Apple", value[3])
    assert.match("highlight Bananna", value[4])
    assert.match("highlight Strawberry guifg=red", value[5])

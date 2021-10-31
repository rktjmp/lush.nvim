describe "export", ->
  -- note, "export" is a protected keyword in moonscript
  exp = require("lush.export")

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

  it "does some smoke tests", ->
    assert.has_error(->
      exp("theme"))
    assert.has_error(->
      exp(1))

  it "warns if a transformation doesn't return a table", ->
    to_string_transform = (ast) ->
      "A.gui=#{ast.A.gui}"
    assert.has_error(->
      exp("theme", to_string_transform))

  it "passes through 1 arity functions", ->
    to_string = (ast) ->
      {"A.gui=#{ast.A.gui}"}

    to_uppercase = (lines) ->
      {string.upper(lines[1])}

    assert.same(exp("theme", to_string), {"A.gui=italic"})
    assert.same(exp("theme", to_string, to_uppercase), {"A.GUI=ITALIC"})

  it "passes through 1 arity functions", ->
    to_string = (ast) ->
      {"A.gui=#{ast.A.gui}"}

    to_uppercase = (lines) ->
      {string.upper(lines[1])}

    assert.same(exp("theme", to_string), {"A.gui=italic"})
    assert.same(exp("theme", to_string, to_uppercase), {"A.GUI=ITALIC"})

  it "passes through multi arity functions", ->
    to_string = (ast, append) ->
      {"A.gui=#{ast.A.gui}+#{append}"}

    to_uppercase = (lines, s, e) ->
      {string.sub(string.upper(lines[1]), s, e)}

    assert.same(exp("theme", {to_string, "bort"}), {"A.gui=italic+bort"})
    assert.same(exp("theme", {to_string, "bort"}, {to_uppercase, -4, -1}), {"BORT"})

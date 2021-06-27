index_of = (list, check) ->
  for i, v in ipairs(list)
    if check(v)
      return i
  return nil

any = (list, check) -> index_of(list, check) ~= nil

describe "compiler", ->
  parse = require('lush.parser')
  compile = require('lush.compiler')

  it "defines a highlight group", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg", gui: "italic", sp: "a_sp", blend: 10 }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_equal(1, #compiled)
    assert.is_not_nil(string.find(compiled[1], "guibg=a_bg"))
    assert.is_not_nil(string.find(compiled[1], "guifg=a_fg"))
    assert.is_not_nil(string.find(compiled[1], "gui=italic"))
    assert.is_not_nil(string.find(compiled[1], "guisp=a_sp"))
    assert.is_not_nil(string.find(compiled[1], "blend=10"))

  it "defines a link group", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
      B { A }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_equal(2, #compiled)
    assert.is_true(any(compiled, (cmd) -> string.find(cmd, "highlight! link B A")))

  it "corrects spaces in gui if present", ->
    ast = parse -> {
      A { gui: "bold, italic" },
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.matches("bold,italic", compiled[1])

describe "key exclusion", ->
  parse = require('lush.parser')
  compile = require('lush.compiler')
  it "can exclude keys", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      exclude_keys: {"blend"}
    })
    assert.is_not_nil(compiled)
    assert.matches("italic", compiled[1])
    assert.not.matches("blend", compiled[1])

  it "still exports group it dropping all 'set keys' but still has NONE values for others", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      exclude_keys: {"blend", "gui"}
    })
    assert.is_not_nil(compiled)
    assert.matches("highlight A", compiled[1])
    -- should still include clearers
    assert.matches("guifg=NONE", compiled[1])

  it "drops group if no keys are present", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      exclude_keys: {"blend", "gui", "fg", "bg", "sp"}
    })
    assert.is_not_nil(compiled)
    assert.is(0, #compiled)

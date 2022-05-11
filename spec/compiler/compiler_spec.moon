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
      A { bg: "a_bg", fg: "a_fg", gui: "italic", sp: "a_sp", blend: 10 },
      B { bg: "b_bg", bold: true, italic: true}
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_not_nil(compiled.A)
    assert.is_equal("a_bg", compiled.A.bg)
    assert.is_equal("a_fg", compiled.A.fg)
    assert.is_equal(true, compiled.A.italic)
    assert.is_equal("a_sp", compiled.A.sp)
    assert.is_equal(10, compiled.A.blend)
    assert.is_equal("b_bg", compiled.B.bg)
    assert.is_equal(true, compiled.B.bold)
    assert.is_equal(true, compiled.B.italic)

  it "defines a link group", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
      B { A }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_not_nil(compiled.B)
    assert.is_equal("A", compiled.B.link)

  it "defines a inherit group", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
      B { A, fg: "b_fg" }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_not_nil(compiled.B)
    assert.is_equal("a_bg", compiled.B.bg)
    assert.is_equal("b_fg", compiled.B.fg)

  it "correctly extracts format modifiers", ->
    ast = parse -> {
      A { gui: "bold" },
      B { gui: "bold, italic" },
      C { gui: "  bold italic  " },
      D { gui: "  notbold italic  " },
    }
    compiled = compile(ast)
    assert.is_equal(true, compiled.A.bold)
    assert.is_equal(true, compiled.B.italic)
    assert.is_equal(true, compiled.B.bold)
    assert.is_equal(true, compiled.C.bold)
    assert.is_equal(true, compiled.C.italic)
    assert.is_equal(nil, compiled.D.bold)
    assert.is_equal(true, compiled.D.italic)

  it "inherited gui modifiers default to false if gui is set", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg", gui: "italic bold" }
      B { A, fg: "b_fg", gui: "underline" }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_not_nil(compiled.B)
    assert.is_equal(true, compiled.A.bold)
    assert.is_equal(true, compiled.A.italic)
    assert.is_equal(nil, compiled.B.bold)
    assert.is_equal(nil, compiled.B.italic)
    assert.is_equal(true, compiled.B.underline)

  it "inherited format modifiers behave as expected", ->
    ast = parse -> {
      A { bold: true, italic: false},
      B { A, italic: true, underline: true}
    }
    compiled = compile(ast)
    assert.is_equal(true, compiled.A.bold)
    assert.is_equal(nil, compiled.A.italic)
    assert.is_equal(true, compiled.B.bold)
    assert.is_equal(true, compiled.B.italic)
    assert.is_equal(true, compiled.B.underline)

  it "non-present gui flags are nil, not false", ->
    ast = parse -> {
      A { gui: "bold" },
    }
    compiled = compile(ast)
    assert.is_equal(nil, compiled.A.italic)
    assert.is_equal(true, compiled.A.bold)

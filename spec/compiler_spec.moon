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
      A { bg: "a_bg", fg: "a_fg" }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_equal(1, #compiled)
    assert.is_not_nil(string.find(compiled[1], "guibg=a_bg"))
    assert.is_not_nil(string.find(compiled[1], "guifg=a_fg"))

  it "defines a link group", ->
    ast = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
      B { A }
    }
    compiled = compile(ast)
    assert.is_not_nil(compiled)
    assert.is_equal(2, #compiled)
    assert.is_true(any(compiled, (cmd) -> string.find(cmd, "highlight! link B A")))

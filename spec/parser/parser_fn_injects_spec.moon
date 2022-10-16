describe "parser ts extension", ->
  parse = require('lush.parser')

  it "injects a function that allows defining invalid sym names", ->
    parsed = parse((injects) ->
      sym = injects.sym
      {
        sym("@rust.error") { fg: "red" },
        A {fg: "blue"},
        B sym("@rust.error"),
        C {sym("@rust.error"), bg: "gold"},
        E {bg: sym("@rust.error").fg}
      })
    -- normal spec works
    assert.equals("blue", parsed.A.fg)
    -- funny sym works
    assert.equals("red", parsed["@rust.error"].fg)
    -- can inherit from sym
    assert.equals("red", parsed.B.fg)
    -- can extend sym
    assert.equals("red", parsed.C.fg)
    assert.equals("gold", parsed.C.bg)
    -- can access fields
    assert.equals("red", parsed.E.bg)


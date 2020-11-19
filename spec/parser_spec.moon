describe "parser", ->
  parse = require('lush.parser')

  it "warns on bad input", ->
    assert.error(-> parse(nil))
    assert.error(-> parse(""))
    assert.error(-> parse(1,2,3,4))
    assert.error(-> parse({}))

  it "warns when re-defining a group", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" },
        A { bg: "DUPLICATE" },
        B { bg: "B_BG"},
      }
    error = assert.has_error(fn)
    assert.matches("redefined", error)

  it "should define a style", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt" }
    }
    assert.is_not_nil(s)
    assert.is_not_nil(s.A)
    assert.is_equal(s.A.bg, "a_bg")
    assert.is_equal(s.A.fg, "a_fg")
    assert.is_equal(s.A.opt, "a_opt")

  it "should allow accesing previous styles", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
    }
    assert.is_equal(s.B.bg, "a_bg")
    assert.is_equal(s.B.fg, "b_fg")
    assert.is_equal(s.B.opt, nil)

  it "should allow linking", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
      C { A }
    }
    assert.is_equal("a_bg", s.A.bg)
    assert.is_not_nil(s.C)
    assert.is_equal('A', s.C.link)

  it "should allow chained linking", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
      C { A } -- C -> A
      D { C } -- D -> C
      E { C } -- E -> C
    }

    assert.is_not_nil(s.C)
    assert.is_equal('A', s.C.link)
    assert.is_not_nil(s.D)
    assert.is_equal('C', s.D.link)
    assert.is_not_nil(s.D)
    assert.is_equal('C', s.E.link)

  it "can resolve links during compile", ->
    s =  parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
      C { A } -- C -> A
      D { C } -- D -> C
      E { C } -- E -> C
      F { bg: E.bg, fg: B.fg } -- bg -> E -> C -> A.bg, fg -> B.fg
    }

    assert.is_not_nil(s.F)
    assert.is_equal("b_fg", s.F.fg)
    assert.is_equal("a_bg", s.F.bg)

  it "has unique tables for all groups", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
      C { A } -- C -> A
      D { C } -- D -> C
      E { C } -- E -> C
      F { bg: E.bg, fg: B.fg } -- bg -> E -> C -> A.bg, fg -> B.fg
    }
    assert.is_not_equal(s.A, s.B, s.C, s.D, s.E, s.F)
  
  it "warns when linking to an invalid style", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" }
        X { Z }
      }
    error = assert.has_error(fn)
    assert.matches("X", error)
    assert.matches("Z", error)
  
  it "protects __name", ->
    fn = ->
      parse -> {
        A { bg: "a_bg", fg: "a_fg", __name: "failure" },
      }
    error = assert.has_error(fn)
    assert.matches("__name", error)
    assert.matches("reserved_keyword", error)

  it "defines __type meta key", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", opt: "a_opt" }
    }
    assert.equal('parsed_lush_spec', s.__type)

  it "is a closure", ->
    math = math
    spec =-> {
      A { bg: math.random(0, 10) },
    }
    parsed = parse(spec)
    assert.not_nil(parsed)
    assert.not_nil(parsed.A.bg)
    assert.is_number(parsed.A.bg)
    assert.is_true(parsed.A.bg > 0 and parsed.A.bg < 10)


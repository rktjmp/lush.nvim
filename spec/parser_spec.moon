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

  it "errors on placeholder groups", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" },
        B { bg: Z },
      }
    error = assert.has_error(fn)
    assert.matches("undefined_group", error)

  it "should define a style", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
    }
    assert.is_not_nil(s)
    assert.is_not_nil(s.A)
    assert.is_equal(s.A.bg, "a_bg")
    assert.is_equal(s.A.fg, "a_fg")

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

  pending "it detects loops in chained links", ->
    -- kind of a pain to check this, can't check
    -- by name, must resolve all objects out...
    -- even then, how often would someone do this?
    -- work vs reward?

  it "warns on self referencing links", ->
    e = assert.error(-> parse -> {
      A { bg: "a_bg", fg: "a_fg" },
      C { C }
    })
    e = assert.matches("circular_self_reference", e)


  it "can resolve deep chains", ->
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

  it "warns when linking to an undefined group", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" }
        X { Z }
      }
    error = assert.has_error(fn)
    assert.matches("invalid_link_name", error)
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

  describe "inheritance", ->
    it "can inherit", ->
      parsed = parse -> {
        A { bg: "a_bg" },
        B { A, gui: "italic" },
      }
      assert.equals("italic", parsed.B.gui)
      assert.equals("a_bg", parsed.B.bg)

    it "detects self reference", ->
      e = assert.error(-> parse -> {
        A { bg: "a_bg" },
        B { B, gui: "italic" },
      })
      assert.matches("circular_self_reference", e)

    it "detects invalid references", ->
      e = assert.error(-> parse -> {
        A { bg: "a_bg" },
        B { Z, gui: "italic" },
      })
      assert.matches("invalid_parent_name", e)

    it "can inherit through a link", ->
      parsed = parse -> {
        A { bg: "a_bg" },
        B { A },
        C { B, gui: "italic" },
      }
      assert.equals("italic", parsed.C.gui)
      assert.equals("a_bg", parsed.C.bg)

    it "can inherit through a chain", ->
      parsed = parse -> {
        A { bg: "a_bg" },
        B { A },
        C { B },
        D { C, gui: "italic" },
      }
      assert.equals("italic", parsed.D.gui)
      assert.equals("a_bg", parsed.D.bg)

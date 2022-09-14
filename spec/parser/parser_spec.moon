describe "parser", ->
  parse = require('lush.parser')

  it "warns not to use property inference", ->
    e = assert.error(-> parse -> {
      A { fg: "red" },
      B { fg: A }
    })
    -- error type now different though test remains important
    assert.matches("group_value_is_group", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "warns on bad input", ->
    bads = {
      -> parse(nil),
      -> parse(""),
      -> parse(1,2,3,4,5),
      -> parse({})
      -> parse(-> A { fg: 1, 1 })
    }

    for bad in *bads
      e = assert.error(bad)
      assert.matches("malformed_lush_spec", e.code)
      assert.not.matches("No message avaliable", e.msg)

  it "errors on bad definition", ->
    e = assert.has_error(->
      parse -> {
        A("string"),
      })
    assert.matches("invalid_group_options", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "warns when re-defining a group", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" },
        A { bg: "DUPLICATE" },
        B { bg: "B_BG"},
      }
    e = assert.has_error(fn)
    assert.matches("group_redefined", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "errors on placeholder groups", ->
    fn = ->
      parse -> {
        A { bg: "a_bg" },
        B { bg: Z },
      }
    error = assert.has_error(fn)
    assert.matches("undefined_group", error.code)

  it "errors on bad group names", ->
    e = assert.has_error(-> parse -> {
      _ { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)

    -- 1 { ... }, [1] { } are uncompilable moonscript

    -- vim reserved keywords
    e = assert.has_error(-> parse -> {
      ALL { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)
    e = assert.has_error(-> parse -> {
      NONE { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)
    e = assert.has_error(-> parse -> {
      ALLBUT { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)
    e = assert.has_error(-> parse -> {
      contained { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)
    e = assert.has_error(-> parse -> {
      contains { bg: "bg" },
    })
    assert.matches("invalid_group_name", e.code)

    -- contains keyword but isnt
    e = assert.not.has_error(-> parse -> {
      ALLhere { bg: "bg" },
    })
    e = assert.not.has_error(-> parse -> {
      NONEthere { bg: "bg" },
    })
    e = assert.not.has_error(-> parse -> {
      ALLBUTme { bg: "bg" },
    })
    e = assert.not.has_error(-> parse -> {
      containedinabag { bg: "bg" },
    })
    e = assert.not.has_error(-> parse -> {
      containshambuger { bg: "bg" },
    })

  it "should define a style", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg" }
    }
    assert.is_not_nil(s)
    assert.is_not_nil(s.A)
    assert.is_equal(s.A.bg, "a_bg")
    assert.is_equal(s.A.fg, "a_fg")

  it "should only keep keys on allowed keys list", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "abc", not_lush: "xyz", sp: "a_sp", blend: "20"},
    }
    assert.is_not_nil(s.A)
    assert.is_equal(s.A.bg, "a_bg")
    assert.is_equal(s.A.fg, "a_fg")
    assert.is_equal(s.A.lush, "abc")
    assert.is_equal(s.A.blend, "20")
    assert.is_equal(s.A.sp, "a_sp")
    assert.is_equal(s.A.not_lush, nil)

  it "should allow accesing previous styles", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
    }
    assert.is_equal(s.B.bg, "a_bg")
    assert.is_equal(s.B.fg, "b_fg")
    assert.is_equal(s.B.lush, nil)

  it "it exports hidden meta data in __lush", ->
    base_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
      B { A },
    }
    base = parse(base_spec)
    assert.is_not_nil(base.A)
    assert.is_not_nil(base.A.fg)
    assert.is_not_nil(base.A.__lush)
    assert.match("A", base.A.__lush.group_name)
    assert.match("lush_group", base.A.__lush.type)

    assert.is_not_nil(base.B)
    assert.is_not_nil(base.B.__lush)
    assert.match("B", base.B.__lush.group_name)
    assert.match("lush_group_link", base.B.__lush.type)

  pending "Enforces group names must begin with alpha character", ->

  it "should allow linking", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt"}
      B { bg: A.bg, fg: "b_fg" }
      C { A }
    }
    assert.is_equal("a_bg", s.A.bg)
    assert.is_not_nil(s.C)
    assert.is_equal('A', s.C.link)

  it "should allow chained linking", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt"}
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
    assert.matches("circular_self_link", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "can resolve deep chains", ->
    s =  parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt"}
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
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt"}
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
    assert.matches("invalid_link_name", error.code)
    assert.matches("X", error.on)
    assert.matches("Z", error.msg)

  it "protects __lush", ->
    parsed = parse -> {
      A { bg: "a_bg", fg: "a_fg", __lush: "failure" },
    }
    -- __lush will exist
    assert.not_nil(parsed.A.__lush)
    -- but wont be what we tried to set
    assert.not.is_string(parsed.A.__lush)

  it "defines __lush meta key", ->
    s = parse -> {
      A { bg: "a_bg", fg: "a_fg", lush: "a_opt" }
    }
    assert.equal('parsed_lush_spec', s.__lush.type)

  it "is a closure", ->
    math = math
    spec = -> {
      A { bg: math.huge },
    }
    parsed = parse(spec)
    assert.not_nil(parsed)
    assert.not_nil(parsed.A.bg)
    assert.is_number(parsed.A.bg)
    assert.is_true(parsed.A.bg == math.huge)

  describe "inheritance", ->
    it "can inherit", ->
      parsed = parse -> {
        A { bg: "a_bg", lush: "inherit", not_lush: "lost" },
        B { A, gui: "italic", also_lost: "this"},
      }
      assert.equals("italic", parsed.B.gui)
      assert.equals("a_bg", parsed.B.bg)
      assert.equals("inherit", parsed.B.lush)
      assert.equals(nil, parsed.B.not_lush)
      assert.equals(nil, parsed.B.also_lost)

    it "limits parents to 1", ->
      e = assert.error(-> parse -> {
        A { fg: "red" },
        B { A },
        C { B, bg: "blue", A} -- Failure
      })
      assert.matches("too_many_parents", e.code)
      assert.not.matches("No message avaliable", e.msg)

    it "can have a useless inherit", ->
      -- useless: inherit but redefine all properties
      -- TODO: you could warn/error on this case, but may be more frustrating
      -- than useful
      parsed = parse -> {
        A { bg: "a_bg" },
        B { A, bg: "b_bg", gui: "italic" },
      }
      assert.equals("italic", parsed.B.gui)
      assert.equals("b_bg", parsed.B.bg)

    -- 2021-03-07-1505
    -- circular_self_reference now allowed to support
    -- A { parent.A, fg = ... } extensions
    -- invalid self references are still caught
    -- by invalid_parent or group_redefined
    -- it "detects self reference", ->
    --   e = assert.error(-> parse -> {
    --     A { bg: "a_bg" },
    --     B { B, gui: "italic" },
    --   })
    --   assert.matches("circular_self_inherit", e.code)
    --   assert.not.matches("No message avaliable", e.msg)

    it "detects invalid references", ->
      e = assert.error(-> parse -> {
        A { bg: "a_bg" },
        B { Z, gui: "italic" },
      })
      assert.matches("invalid_parent", e.code)
      assert.not.matches("No message avaliable", e.msg)

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


describe "lush", ->
  parse = require('lush').parse

  it "self link will error", ->
    base_spec = -> {
      Comment { fg: "red" }
    }
    base = parse(base_spec)

    my_spec = -> {
      Comment { base.Comment }
    }
    e = assert.has_error(-> parse(my_spec))
    assert.matches("circular_self_link", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "can chain through external specs", ->
    base_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
      Z { A },
    }
    base = parse(base_spec)

    another_spec = -> {
      B { fg: base.A.fg }, -- direct prop
      C { base.A, bg: "c_bg" }, -- extend with
      D { base.A }, -- link to external
      E { base.Z }, -- multi-interection link though external link
      F { base.Z, bg: "f_bg" }
    }
    another = parse(another_spec)

    -- spec doesn't die
    assert.not_nil(another)

    -- we can get values directly
    assert.is_not_nil(another.B)
    assert.is_not_nil(another.B.fg)
    assert.is_equal(another.B.fg, "a_fg")

    -- we can inherit from the ext
    assert.is_equal(another.C.fg, "a_fg")
    assert.is_equal(another.C.bg, "c_bg")

    -- we can link to an external
    assert.is_not_nil(another.D)
    assert.is_equal(another.D.fg, "a_fg")
    assert.is_equal(another.D.bg, "a_bg")

    -- we can link though an indirect link
    assert.is_not_nil(another.E)
    assert.is_equal(another.E.fg, "a_fg")
    assert.is_equal(another.E.bg, "a_bg")

    -- wf cah inherit through an indirect link
    assert.is_not_nil(another.F)
    assert.is_equal(another.F.fg, "a_fg")
    assert.is_equal(another.F.bg, "f_bg")



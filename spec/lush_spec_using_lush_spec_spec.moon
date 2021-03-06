describe "lush", ->
  lush = require('lush')
  red = lush.hsl(0, 100, 50)
  green = lush.hsl(120, 100, 50)
  blue = lush.hsl(240, 100, 50)

  it "it exports hidden meta data in __lush", ->
    base_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
      B { A },
    }
    base = lush(base_spec)
    assert.is_not_nil(base.A)
    assert.is_not_nil(base.A.fg)
    assert.is_not_nil(base.A.__lush)
    assert.match("A", base.A.__lush.group_name)
    assert.match("lush_group", base.A.__lush.type)

    assert.is_not_nil(base.B)
    assert.is_not_nil(base.B.__lush)
    assert.match("B", base.B.__lush.group_name)
    assert.match("lush_group_link", base.B.__lush.type)

  it "can chain through external specs", ->
    base_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
      Z { A },
    }
    base = lush(base_spec)

    another_spec = -> {
      B { fg: base.A.fg }, -- direct prop
      C { base.A, bg: "c_bg" }, -- extend with
      D { base.A }, -- link to external
      E { base.Z }, -- multi-interection link though external link
      F { base.Z, bg: "f_bg" }
    }
    another = lush(another_spec)

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



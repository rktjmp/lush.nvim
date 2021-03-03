describe "lush", ->
  lush = require('lush')
  red = lush.hsl(0, 100, 50)
  green = lush.hsl(120, 100, 50)
  blue = lush.hsl(240, 100, 50)

  it "can chain through imported specs", ->
    base_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }
    base = lush(base_spec)

    another_spec = -> {
      B { fg: base.A.fg }, -- direct prop
      C { pase.A } -- linked
    }
    another = lush(another_spec)

    assert.not_nil(another)
    assert.is_not_nil(another.B)
    assert.is_not_nil(another.B.fg)
    assert.is_not_nil(another.B)
    assert.is_not_nil(another.B.fg)
    assert.is_equal(another.B.fg, "a_fg")


describe "hsl creation", ->
  hsl = require('lush.hsl')

  it "creates colors", ->
    assert.is.not.nil(hsl)
    color = hsl(120, 10, 10)
    assert.not.nil(color)
    color = hsl(361, 111, 302)
    assert.is.equal(color.h, 1)
    assert.is.equal(color.s, 100)
    assert.is.equal(color.l, 100)

    color = hsl(-365, -111, -102)
    assert.is.equal(color.h, 355)
    assert.is.equal(color.s, 0)
    assert.is.equal(color.l, 0)

  it "unrolls when called", ->
    color = hsl(120, 11, 34)
    assert.not.nil(color())
    assert.is.table(color())
    assert.is.equal(color().h, 120)
    assert.is.equal(color().s, 11)
    assert.is.equal(color().l, 34)

  it "has .h, .s, .l helpers", ->
    color = hsl(120, 11, 34)
    assert.is.equal(color.h, 120)
    assert.is.equal(color.s, 11)
    assert.is.equal(color.l, 34)

  it "can apply modifiers", ->
    color = hsl(120, 11, 34)
    assert.is.equal(color.h, 120)
    assert.is.equal(color.rotate(10).h, 130)
    assert.is.equal(color.rotate(-10).h, 110)
    assert.is.equal(color.rotate(-120).h, 0)
    assert.is.equal(color.rotate(-125).h, 355)

    assert.is.equal(color.s, 11)
    assert.is.equal(color.saturate(10).s, 21)
    assert.is.equal(color.saturate(-10).s, 1)
    assert.is.equal(color.saturate(-110).s, 0)
    assert.is.equal(color.saturate(110).s, 100)

    assert.is.equal(color.l, 34)
    assert.is.equal(color.lighten(10).l, 44)
    assert.is.equal(color.lighten(-10).l, 24)
    assert.is.equal(color.lighten(-110).l, 0)
    assert.is.equal(color.lighten(110).l, 100)

    assert.is.equal(color.h, 120)
    assert.is.equal(color.hue(55).h, 55)

    assert.is.equal(color.s, 11)
    assert.is.equal(color.saturation(55).s, 55)

    assert.is.equal(color.l, 34)
    assert.is.equal(color.lightness(44).l, 44)

  it "can chain modifiers", ->
    color = hsl(120, 11, 34)
    mod_color = color.rotate(10).lighten(20).desaturate(20).rotate(20)
    assert.is_same(mod_color(), {h: 150, s: 0, l: 54})

  it "can modifiers don't modifiy original color", ->
    color = hsl(120, 11, 34)
    mod_color = color.rotate(10).lighten(20).desaturate(20).rotate(20)
    assert.is_not_equal(color, mod_color)

  it "can concat with strings", ->
    color = hsl(0,0,0)
    str_start = "my color is: "
    assert.is_equal(str_start .. "#000000", str_start .. color)

  it "can build from a hex value", ->
    color = hsl("#FF0000")
    assert.is_equal(0, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(50, color.l)
    color = hsl("#00FF00")
    assert.is_equal(120, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(50, color.l)
    color = hsl("#0000fF")
    assert.is_equal(240, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(50, color.l)
    color = hsl("#fe20d5")
    assert.is_equal(311, color.h)
    assert.is_equal(99, color.s)
    assert.is_equal(56, color.l)
    assert.error(-> color hsl(""))
    assert.error(-> color hsl("hsl('#100000')"))
    assert.error(-> color hsl("#0df"))
    assert.error(-> color hsl("#00FF0Z"))

  it "can convert to hex", ->
    color = hsl(0, 0, 0)
    assert.is_equal("#000000", tostring(color))

    assert.is.equal(hsl(0,0,0).hex, "#000000")
    assert.is.equal(hsl(120, 0, 0).hex, "#000000")
    assert.is.equal(hsl(0,0,100).hex, "#FFFFFF")
    assert.is.equal(hsl(0, 100, 50).hex, "#FF0000")
    assert.is.equal(hsl(120, 100, 50).hex, "#00FF00")
    assert.is.equal(hsl(240, 100, 50).hex, "#0000FF")
    assert.is.equal(hsl(123, 45, 67).hex, "#85D189")

    assert.is_equal(hsl(0,0,0) .. " color", "#000000 color")
    assert.is_equal("color " .. hsl(0,0,0), "color #000000")

  it "disables assignment", ->
    color = hsl(0, 0, 0)
    assert.error(-> color.h = 100)

  it "has shorthands", ->
    color = hsl(90, 50, 50)
    assert.is_equal(190, color.ro(100).h)
    assert.is_equal(60, color.sa(10).s)
    assert.is_equal(40, color.de(10).s)
    assert.is_equal(60, color.li(10).l)
    assert.is_equal(40, color.da(10).l)
    assert.is_equal(75, color.sar(50).s)
    assert.is_equal(25, color.der(50).s)
    assert.is_equal(75, color.lir(50).l)
    assert.is_equal(25, color.dar(50).l)

  it "has relative adjustment", ->
    color = hsl(90, 50, 50)
    assert.is_equal(75, color.saturate_rel(50).s) -- 50% more
    assert.is_equal(25, color.desaturate_rel(50).s) -- 50% less
    assert.is_equal(75, color.lighten_rel(50).l)
    assert.is_equal(25, color.darken_rel(50).l)
    assert.is_equal(100, color.saturate_rel(100).s) -- 100% more aka 2x
    assert.is_equal(100, color.saturate_rel(200).s) -- 200% more aka 3x, caps
    assert.error(-> color.rotate_rel(100)) -- invalid

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

  it "can convert to hex", ->
    color = hsl(0, 0, 0)
    assert.is.equal(hsl(0,0,0).as_hex, "#000000")
    assert.is.equal(hsl(120, 0, 0).as_hex, "#000000")
    assert.is.equal(hsl(0,0,100).as_hex, "#FFFFFF")
    assert.is.equal(hsl(0, 100, 50).as_hex, "#FF0000")
    assert.is.equal(hsl(120, 100, 50).as_hex, "#00FF00")
    assert.is.equal(hsl(240, 100, 50).as_hex, "#0000FF")
    assert.is.equal(hsl(123, 45, 67).as_hex, "#84D088")

    assert.is_equal(hsl(0,0,0) .. " color", "#000000 color")
    assert.is_equal("color " .. hsl(0,0,0), "color #000000")

  it "tests assignment", ->
    color = hsl(0, 0, 0)
    assert.error(-> color.h = 100)


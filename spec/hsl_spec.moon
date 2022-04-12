describe "hsl", ->
  hsl = require('lush.vivid.hsl.type')

  describe "creation", ->
    it "can be created from h,s,l", ->
      color = hsl(120, 10, 10)
      assert.not.nil(color)
      color = hsl(361, 111, 302)
      assert.is.equal(color.h, 1)
      assert.is.equal(color.s, 100)
      assert.is.equal(color.l, 100)

  it "can be created from a hex value", ->
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

    color = hsl("#808080")
    assert.is_equal(0, color.h)
    assert.is_equal(0, color.s)
    assert.is_equal(50, color.l)

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

  it "can convert to rgb", ->
    color = hsl(100, 50, 50)
    rgb = color.rgb
    assert.is_equal(106, rgb.r)
    assert.is_equal(191, rgb.g)
    assert.is_equal(64, rgb.b)

  describe "modification", ->
    color = hsl(120, 11, 34)

    it "has an operation", ->
      assert.is.equal(120 + 40, color.rotate(40).h)
      -- assumed rest is tested by hsl_like

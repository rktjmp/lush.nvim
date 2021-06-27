describe "hsluv", ->
  hsluv = require('lush.vivid.hsluv.type')

  describe "creation", ->
    it "can be created from h,s,l", ->
      color = hsluv(120, 10, 10)
      assert.not.nil(color)
      color = hsluv(361, 111, 302)
      assert.is.equal(color.h, 1)
      assert.is.equal(color.s, 100)
      assert.is.equal(color.l, 100)

  it "can be created from a hex value", ->
    color = hsluv("#FF0000")
    assert.is_equal(12, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(53, color.l)

    color = hsluv("#00FF00")
    assert.is_equal(128, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(88, color.l)

    color = hsluv("#0000fF")
    assert.is_equal(266, color.h)
    assert.is_equal(100, color.s)
    assert.is_equal(32, color.l)

    color = hsluv("#fe20d5")
    assert.is_equal(323, color.h)
    assert.is_equal(99, color.s)
    assert.is_equal(59, color.l)

    color = hsluv("#808080")
    assert.is_equal(0, color.h)
    assert.is_equal(0, color.s)
    assert.is_equal(54, color.l)

  it "can convert to hex", ->
    color = hsluv(0, 0, 0)
    assert.is_equal("#000000", tostring(color))

    assert.is.equal(hsluv(0, 0, 0).hex, "#000000")
    assert.is.equal(hsluv(120, 0, 0).hex, "#000000")
    assert.is.equal(hsluv(0, 0, 100).hex, "#FFFFFF")
    assert.is.equal(hsluv(0, 100, 50).hex, "#EA0064")
    assert.is.equal(hsluv(120, 100, 50).hex, "#3F8700")
    assert.is.equal(hsluv(240, 100, 50).hex, "#007EB7")
    assert.is.equal(hsluv(123, 45, 67).hex, "#80AF77")

    assert.is_equal(hsluv(0,0,0) .. " color", "#000000 color")
    assert.is_equal("color " .. hsluv(0,0,0), "color #000000")

  describe "modification", ->
    color = hsluv(120, 11, 34)

    it "has an operation", ->
      assert.is.equal(120 + 40, color.rotate(40).h)
      -- assumed rest is tested by hsl_like

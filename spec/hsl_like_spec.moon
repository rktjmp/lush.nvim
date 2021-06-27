describe "hsl_like", ->
  hsl_like = require('lush.vivid.hsl_like')
  hsl = hsl_like

  type_fns = {
    name: -> "type_name",
    to_hex: -> "#000000",
    from_hex: -> {h: 100, s: 50, l: 50}
  }

  describe "require", ->
    it "exports a function", ->
      assert.is.not.nil(hsl_like)
      assert.is.function(hsl_like)

  describe "init checks", ->
    it "checks for from_hex", ->
      init_fns = {name: -> "test"}
      assert.error((-> hsl_like(100, 10, 10, init_fns)), "test must provide from_hex() type_fn")

    it "checks for to_hex", ->
      init_fns = {
        name: -> "test",
        from_hex: -> ""
      }
      assert.error((-> hsl_like(100, 10, 10, init_fns)), "test must provide to_hex() type_fn")

  describe "creation", ->
    it "can be created from h,s,l", ->
      color = hsl_like(120, 10, 10, type_fns)
      assert.not.nil(color)

      color = hsl_like(361, 111, 302, type_fns)
      assert.is.equal(color.h, 1)
      assert.is.equal(color.s, 100)
      assert.is.equal(color.l, 100)

      -- these values should just be clamped
      color = hsl_like(-365, -111, -102, type_fns)
      assert.is.equal(color.h, 355)
      assert.is.equal(color.s, 0)
      assert.is.equal(color.l, 0)

  it "can be created from a hex value", ->
    color = hsl_like("#000000", nil, nil, type_fns)
    assert.is_equal(100, color.h)
    assert.is_equal(50, color.s)
    assert.is_equal(50, color.l)

  it "errors on bad arguments", ->
    check_e = (fn) ->
      e = assert.error(fn)
      assert.matches("type_name expects", e)
    assert.error((-> hsl_like()), "must provide type_fns")
    assert.error((-> hsl_like(1)), "must provide type_fns")
    assert.error((-> hsl_like(1,2)), "must provide type_fns")
    assert.error((-> hsl_like(1,2,3)), "must provide type_fns")

    check_e(-> hsl_like(1,2, nil, type_fns))
    check_e(-> hsl_like(2, 3, "3", type_fns))

    e = assert.error(-> color hsl_like("", nil, nil, type_fns))
    assert.matches("invalid hex_str", e)
    e = assert.error(-> color hsl_like("hsl('#100000')", nil, nil, type_fns))
    assert.matches("invalid hex_str", e)
    e = assert.error(-> color hsl_like("#0df", nil, nil, type_fns))
    assert.matches("invalid hex_str", e)
    e = assert.error(-> color hsl_like("#00FF0Z", nil, nil, type_fns))
    assert.matches("invalid hex_str", e)

  describe "unpacking", ->
    it "unrolls to table when called", ->
      color = hsl_like(120, 11, 34, type_fns)
      assert.not.nil(color())
      assert.is.table(color())
      assert.is.equal(color().h, 120)
      assert.is.equal(color().s, 11)
      assert.is.equal(color().l, 34)

    it "has .h, .s, .l helpers", ->
      color = hsl_like(120, 11, 34, type_fns)
      assert.is.equal(color.h, 120)
      assert.is.equal(color.s, 11)
      assert.is.equal(color.l, 34)

    it "disables assignment", ->
      color = hsl(0, 0, 0, type_fns)
      e = assert.error(-> color.h = 100)
      assert.matches("Member setting disabled", e)
      e = assert.error(-> color.s = 100)
      assert.matches("Member setting disabled", e)
      e = assert.error(-> color.l = 100)
      assert.matches("Member setting disabled", e)

    it "can concat with strings", ->
      color = hsl_like(0,0,0, type_fns)
      str_start = "my color is: "
      assert.is_equal(str_start .. "#000000", str_start .. color)

    it "can convert to hex", ->
      color = hsl_like(0, 0, 0, type_fns)
      assert.is_equal("#000000", tostring(color))

  describe "modification", ->
    color = hsl(120, 11, 34, type_fns)

    it "can warns on bad operation", ->
      e = assert.error(-> color.garbage(100))
      assert.matches("valid operations: ", e)

    it "can rotate", ->
      assert.is.equal(color.h, 120)
      assert.is.equal(120, color.rotate(0).h)
      assert.is.equal(120 + 40, color.rotate(40).h)
      assert.is.equal((120 + 240) % 360, color.rotate(240).h)
      assert.is.equal(color.rotate(-10).h, 110)
      assert.is.equal(color.rotate(-120).h, 0)
      assert.is.equal(color.rotate(-125).h, 355)

      assert.is_same(color.rotate(120).h, color.ro(120).h)

      e = assert.error(-> color.rotate())
      assert.matches("number", e)
      e = assert.error(-> color.rotate("asd"))
      assert.matches("number", e)

    it "can saturate", ->
      assert.is.equal(color.s, 11)
      assert.is.equal(color.saturate(10).s, 20)
      assert.is.equal(color.saturate(-10).s, 10)
      assert.is.equal(color.saturate(-110).s, 0)
      assert.is.equal(color.saturate(110).s, 100)

      assert.is.equal(color.abs_saturate(10).s, 21)
      assert.is.equal(color.abs_saturate(-10).s, 1)
      assert.is.equal(color.abs_saturate(-110).s, 0)
      assert.is.equal(color.abs_saturate(110).s, 100)

      assert.is_same(color.saturate(10).s, color.sa(10).s)
      assert.is_same(color.abs_saturate(10).s, color.abs_sa(10).s)

      e = assert.error(-> color.saturate())
      assert.matches("number", e)
      e = assert.error(-> color.saturate("asd"))
      assert.matches("number", e)

    it "can desaturate", ->
      assert.is.equal(color.s, 11)
      assert.is.equal(color.desaturate(10).s, 10)
      assert.is.equal(color.desaturate(-10).s, 20)
      assert.is.equal(color.desaturate(-110).s,100)
      assert.is.equal(color.desaturate(110).s, 0)

      assert.is.equal(color.s, 11)
      assert.is.equal(color.abs_desaturate(10).s, 1)
      assert.is.equal(color.abs_desaturate(-10).s, 21)
      assert.is.equal(color.abs_desaturate(-110).s,100)
      assert.is.equal(color.abs_desaturate(110).s, 0)

      assert.is_same(color.desaturate(10).s, color.de(10).s)
      assert.is_same(color.abs_desaturate(10).s, color.abs_de(10).s)

      e = assert.error(-> color.desaturate())
      assert.matches("number", e)
      e = assert.error(-> color.desaturate("asd"))
      assert.matches("number", e)

    it "can lighten", ->
      assert.is.equal(color.l, 34)
      assert.is.equal(color.lighten(10).l, 41)
      assert.is.equal(color.lighten(-10).l, 31)
      assert.is.equal(color.lighten(-110).l, 0)
      assert.is.equal(color.lighten(110).l, 100)

      assert.is.equal(color.l, 34)
      assert.is.equal(color.abs_lighten(10).l, 44)
      assert.is.equal(color.abs_lighten(-10).l, 24)
      assert.is.equal(color.abs_lighten(-110).l, 0)
      assert.is.equal(color.abs_lighten(110).l, 100)

      assert.is_same(color.lighten(10).l, color.li(10).l)
      assert.is_same(color.abs_lighten(10).l, color.abs_li(10).l)

      e = assert.error(-> color.lighten())
      assert.matches("number", e)
      e = assert.error(-> color.lighten("asd"))
      assert.matches("number", e)

    it "can darken", ->
      assert.is.equal(color.l, 34)
      assert.is.equal(color.darken(10).l, 31)
      assert.is.equal(color.darken(-10).l, 41)
      assert.is.equal(color.darken(-110).l,100)
      assert.is.equal(color.darken(110).l, 0)

      assert.is.equal(color.l, 34)
      assert.is.equal(color.abs_darken(10).l, 24)
      assert.is.equal(color.abs_darken(-10).l, 44)
      assert.is.equal(color.abs_darken(-110).l,100)
      assert.is.equal(color.abs_darken(110).l, 0)

      assert.is_same(color.darken(10).l, color.da(10).l)
      assert.is_same(color.abs_darken(10).l, color.abs_da(10).l)

      e = assert.error(-> color.darken())
      assert.matches("number", e)
      e = assert.error(-> color.darken("asd"))
      assert.matches("number", e)

    it "can set direct values", ->
      assert.is.equal(color.h, 120)
      assert.is.equal(color.hue(55).h, 55)
      assert.is.equal(color.s, 11)
      assert.is.equal(color.saturation(55).s, 55)
      assert.is.equal(color.l, 34)
      assert.is.equal(color.lightness(44).l, 44)

      e = assert.error(-> color.hue())
      assert.matches("number", e)
      e = assert.error(-> color.hue("asd"))
      assert.matches("number", e)
      e = assert.error(-> color.saturation())
      assert.matches("number", e)
      e = assert.error(-> color.saturation("asd"))
      assert.matches("number", e)
      e = assert.error(-> color.lightness())
      assert.matches("number", e)
      e = assert.error(-> color.lightness("asd"))
      assert.matches("number", e)

  describe "mix", ->
    it "0 strength returns base", ->
      color = hsl(123, 50, 100, type_fns)
      assert.is_same(color.hsl, color.mix(hsl(0, 10, 99, type_fns), 0).hsl)

    it "100 strength returns target", ->
      color = hsl(123, 50, 100, type_fns)
      target = hsl(22, 44, 88, type_fns)
      assert.is_same(target.hsl, color.mix(target, 100).hsl)

  describe "modifier behaviour", ->
    it "can chain modifiers", ->
      color = hsl(120, 11, 34, type_fns)
      mod_color = color.rotate(10).lighten(20).desaturate(20).rotate(20)
      assert.is_same({h: 150, s: 9, l: 47}, mod_color.hsl)

    it "can modifiers don't modifiy original color", ->
      color = hsl(120, 11, 34, type_fns)
      mod_color = color.rotate(10).lighten(20).desaturate(20).rotate(20)
      assert.is_not_equal(color, mod_color)
      assert.is_not_equal(color(), mod_color())

pending "parser property inference", ->
  parse = require('lush.parser')

  describe "property inference", ->
    it "can infer a property", ->
      parsed = parse -> {
        A { bg: "a_bg" },
        B { bg: A }
      }
      assert.equals("a_bg", parsed.B.bg)

    it "can infer multiple properties", ->
      parsed = parse -> {
        A { bg: "a_bg" },
        B { fg: "b_fg" },
        C { bg: A, fg: B}
      }
      assert.equals("a_bg", parsed.C.bg)
      assert.equals("b_fg", parsed.C.fg)

      parsed = parse -> {
        A { bg: "a_bg", fg: "a_fg" },
        B { bg: A, fg: A }, -- ok
      }
      assert.equals("a_bg", parsed.B.bg)
      assert.equals("a_fg", parsed.B.fg)

    pending "#only can follow links for inferred values", ->
      -- TODO also pending value function/Maybe type
      parsed = parse -> {
        A { bg: "a_bg"},
        B { A },
        C { bg: B }, -- ok
      }
      assert.nil(parsed)
      assert.equals("a_bg", parsed.C.bg)

    pending "can chain onto inferred properties", ->
      color = {
        ro: (n) -> n * 2
      }
      parsed = parse -> {
        A { bg: color, fg: "a_fg" },
        -- this needs to follow our values are functions plan
        -- aka maybes, though not sure how favorable that
        -- is to external libraries HSL or otherwise.
        -- and only fg/bg would have the behaviour
        B { bg: A.ro(10), fg: A }, -- ok
      }

    it "errors on missing key access", ->
      e = assert.error(->
        parse -> {
          A { bg: "a_bg" },
          B { bg: "b_bg" },
          C { bg: B, fg: A} -- A exists, but no fg key
        })
      assert.matches("target_missing_inferred_key", e)

    it "errors on missing group", ->
      e = assert.error(->
        parse -> {
          A { bg: "a_bg" },
          B { bg: Z },
        })
      assert.matches("undefined_group", e)

      e = assert.error(->
        parse -> {
          A { bg: "a_bg", fg: "a_fg" },
          B { bg: A, fg: C },
          C { fg: "c_bg" },
        })
      assert.matches("undefined_group", e)

    it "errors on self reference", ->
      e = assert.error(->
        parse -> {
          A { bg: "a_bg", fg: "a_fg" },
          B { bg: A, fg: B }, -- error
        })
      assert.matches("circular_self_reference", e)


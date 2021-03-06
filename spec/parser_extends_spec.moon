describe "lush", ->
  parse = require('lush.parser')

  it "only accepts parsed lush specs", ->
    e = assert.has_error(->
      parse((-> {
        B { A }
      }), {extends: ""}))
    assert.matches("malformed_lush_spec_extends_option", e.code)
    assert.not.matches("No message avaliable", e.msg)

    e = assert.has_error(->
      parse((-> {
        B { A }
      }), {extends: {fg: '1'}}))
    assert.matches("malformed_lush_spec_extends_option", e.code)
    assert.not.matches("No message avaliable", e.msg)

  it "inherits all properties of a parent spec", ->
    parent_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }
    parent = parse(parent_spec)

    child_spec = -> {}
    child = parse(child_spec, {extends: {parent}})

    assert.not_nil(child)
    assert.is_not_nil(child.A)
    assert.is_equal(child.A.bg, "a_bg")
    assert.is_equal(child.A.fg, "a_fg")

  it "can make new group from parent", ->
    parent_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }
    parent = parse(parent_spec)

    child_spec = -> {
      B { fg: A.fg, bg: "b_bg"}
    }
    child = parse(child_spec, {extends: {parent}})

    assert.is_not_nil(child.A)
    assert.is_not_nil(child.B)
    assert.is_equal(child.B.fg, "a_fg")
    assert.is_equal(child.B.bg, "b_bg")

  it "concats extensions from first to last", ->
    base = parse -> {
      A { bg: "a_bg" , fg: "a_fg" },
      B { bg: "b_bg", fg: "b_fg" } -- should not end up in final spec
    }

    base_2 = parse -> {
      B { fg: "base_2_b_fg" } -- should overwrite base
    }

    child_spec = -> {
    }
    child = parse(child_spec, {extends: {base, base_2}})

    assert.is_not_nil(child.A)
    assert.is_not_nil(child.B)
    assert.is_equal(child.A.fg, "a_fg")
    assert.is_equal(child.B.fg, "base_2_b_fg")
    assert.is_nil(child.B.bg) -- B was redefined, so bg should be nil

  it "performs lookup from last to first", ->
    base = parse -> {
      A { bg: "a_bg" , fg: "a_fg" },
      B { bg: "b_bg", fg: "b_fg" } -- should not end up in final spec
    }

    base_2 = parse -> {
      B { fg: "base_2_b_fg" } -- should overwrite base
    }

    child_spec = -> {
      B { B }
    }
    child = parse(child_spec, {extends: {base, base_2}})

    -- should prefer base_2 values
    assert.is_equal(child.B.fg, "base_2_b_fg")
    assert.is_nil(child.B.bg) -- B was redefined, so bg should be nil

    -- should prefer base values
    child = parse(child_spec, {extends: {base_2, base}})
    assert.is_equal(child.B.fg, "b_fg")
    assert.is_equal(child.B.bg, "b_bg")

  it "can chain extends", ->
    base = parse -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }

    base_2 = parse((-> {
      B { bg: "b_bg", fg: A.fg },
      C { bg: "c_bg" }
    }), {extends: {base}})

    base_3 = parse((-> {
      D { bg: A.bg, fg: B.fg },
      Z { bg: "z_bg" }
    }), {extends: {base_2}})

    assert.is_equal(base_3.Z.bg, "z_bg")
    assert.is_equal(base_3.D.bg, "a_bg")
    assert.is_equal(base_3.D.fg, "a_fg")
    assert.is_equal(base_3.C.bg, "c_bg")
    assert.is_equal(base_3.B.bg, "b_bg")
    assert.is_equal(base_3.B.fg, "a_fg")

  it "can link to an extended group", ->
    parent_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }
    parent = parse(parent_spec)

    child_spec = -> {
      B { A }
    }
    child = parse(child_spec, {extends: {parent}})

    assert.not_nil(child)
    assert.is_not_nil(child.A)
    assert.is_equal(child.A.bg, "a_bg")
    assert.is_equal(child.A.fg, "a_fg")
    assert.is_equal(child.B.bg, "a_bg")
    assert.is_equal(child.B.fg, "a_fg")

  it "can group inherit from an extended group", ->
    parent_spec = -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }
    parent = parse(parent_spec)

    child_spec = -> {
      B { A, bg: "b_bg" }
    }
    child = parse(child_spec, {extends: {parent}})

    assert.not_nil(child)
    assert.is_not_nil(child.A)
    assert.is_equal(child.A.bg, "a_bg")
    assert.is_equal(child.A.fg, "a_fg")
    assert.is_equal(child.B.bg, "b_bg")
    assert.is_equal(child.B.fg, "a_fg")

  it "chain link", ->
    base = parse -> {
      A { bg: "a_bg" , fg: "a_fg" },
    }

    base_2 = parse((-> {
      B { A }
    }), {extends: {base}})

    base_3 = parse((-> {
      C { B }
      Z { A }
    }), {extends: {base_2}})

    assert.is_equal(base_3.A.fg, "a_fg")
    assert.is_equal(base_3.A.bg, "a_bg")
    assert.is_equal(base_3.B.fg, "a_fg")
    assert.is_equal(base_3.B.bg, "a_bg")
    assert.is_equal(base_3.C.fg, "a_fg")
    assert.is_equal(base_3.C.bg, "a_bg")
    assert.is_equal(base_3.Z.fg, "a_fg")
    assert.is_equal(base_3.Z.bg, "a_bg")

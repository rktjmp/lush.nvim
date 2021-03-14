describe "lush.extends", ->
  lush = require('lush')

  it "should pass to parse(spec, {extends: ...})", ->
    parent = lush(-> {
      A { fg: "a_fg" }
    })

    child = lush((-> {
      B { parent.A }
    }), {extends: {parent}})

    assert.is_equal(child.B.fg, parent.A.fg)

  it "extends({parent}).with(spec)", ->
    parent = lush(-> {
      A { fg: "a_fg" }
    })

    child = lush.extends({parent}).with(-> { B { parent.A } })
    assert.is_equal(child.B.fg, parent.A.fg)

  it "extends({parent, parent}).with(spec)", ->
    parent_a = lush(-> {
      A { fg: "a_fg" }
    })

    parent_b = lush(-> {
      B { fg: "b_fg" }
    })

    child = lush.extends({parent_a, parent_b}).with(-> { C { parent_a.A } })
    assert.is_equal(child.A.fg, parent_a.A.fg)
    assert.is_equal(child.B.fg, parent_b.B.fg)
    assert.is_equal(child.C.fg, parent_a.A.fg)
    assert.is_equal(child.C.bg, parent_a.A.bg)

describe "lush.merge", ->
  lush = require('lush')

  it "merge({parent})", ->
    parent = lush(-> {
      A { fg: "a_fg" }
    })

    child = lush.merge({parent})
    assert.is_equal(child.A.fg, parent.A.fg)

  it "merge({parent, parent})", ->
    parent_a = lush(-> {
      A { fg: "a_fg" }
    })

    parent_b = lush(-> {
      B { fg: "b_fg" }
    })

    child = lush.merge({parent_a, parent_b})
    assert.is_equal(child.A.fg, parent_a.A.fg)
    assert.is_equal(child.B.fg, parent_b.B.fg)



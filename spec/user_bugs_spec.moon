describe "user bugs", ->
  parse = require('lush').parse

  -- https://github.com/rktjmp/lush.nvim/commit/7103ea77d738ef48c983491b22ae2ca4f797dbbc#r47924319
  -- https://github.com/kunzaatko/nord.nvim/issues/2
  it "gives better warning if inherit isn't a table", ->
    spec = -> {
      A { fg: "a_fg", bg: "a_bg", "inverse"}
    }
    e = assert.error(-> parse(spec))
    assert.matches("target_not_lush_type", e.code)
    assert.not.matches("No message avaliable", e.msg)

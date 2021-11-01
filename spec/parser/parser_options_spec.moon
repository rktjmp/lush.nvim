describe "lush", ->
  parse = require('lush.parser')

  it "only accepts parsed lush specs", ->
    e = assert.has_error(->
      parse((-> {
        B { A }
      }), ""))
    assert.matches("malformed_lush_spec_options", e.code)
    assert.not.matches("No message avaliable", e.msg)

    e = assert.has_error(->
      parse((-> {
        B { A }
      }), 1))
    assert.matches("malformed_lush_spec_options", e.code)
    assert.not.matches("No message avaliable", e.msg)

describe "lush", ->
  lush = require('lush')
  nvim_command_spy, red, green, blue = nil
  lush_spec = nil

  before_each ->
    vim = {
    }
    _G.vim = mock(vim)
    red = lush.hsl(0, 100, 50)
    green = lush.hsl(120, 100, 50)
    blue = lush.hsl(240, 100, 50)
    lush_spec = -> {
      Normal { bg: red, fg: blue },
      CursorLine { bg: green, fg: red, gui: "bold" }
      NormalFloat { Normal },
      PmemuSel { blend: 10 }
    }

  it "propagates load errors", ->
    assert.errors(->
      lush.build("fake_file"))

    assert.errors(->
      lush.build("spec/build/malformed_build_file.lua"))

  it "runs a build file with an injected context", ->
    -- build_file.lua also performs work, checking that a prescribed set of
    -- functions are availible inside it.
    assert.no.errors(->
      lush.build("spec/build/build_file.lua"))

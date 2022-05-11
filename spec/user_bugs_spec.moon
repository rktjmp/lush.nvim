describe "user bugs", ->
  parse = require('lush').parse
  compile = require('lush').compile
  apply = require('lush').apply


  describe "better warnings if inherit isn't a table", ->
    -- https://github.com/rktjmp/lush.nvim/commit/7103ea77d738ef48c983491b22ae2ca4f797dbbc#r47924319
    -- https://github.com/kunzaatko/nord.nvim/issues/2
    it "passes user bug", ->
      spec = -> {
        A { fg: "a_fg", bg: "a_bg", "inverse"}
      }
      e = assert.error(-> parse(spec))
      assert.matches("target_not_lush_type", e.code)
      assert.not.matches("No message avaliable", e.msg)

  describe "generates well formed highlights when keys are empty", ->
    -- https://github.com/npxbr/gruvbox.nvim/issues/30
    -- https://github.com/rktjmp/lush.nvim/pull/28
    it "passes user bug", ->
      spec = -> {
        A { fg: "a_fg", bg: "a_bg", gui: ''}
      }

      -- parsed spec retains empty key
      parsed = parse(spec)
      assert.equal('', parsed.A.gui)

      -- compiler converts to none
      compiled = compile(parsed)
      assert.is_nil(compiled.A.bold)

    it "also handles nil", ->
      spec = -> {
        A { fg: "a_fg", bg: nil, gui: ''}
      }

      -- parsed spec retains empty key
      parsed = parse(spec)
      -- technically not there, nil key-value are "natural" to lua
      assert.equal(nil, parsed.A.bg)

      -- compiler converts to nil
      compiled = compile(parsed)
      assert.is_nil(compiled.A.bg)

  describe "#69", ->
    -- TODO Seems this test case is somewhat incomplete no?
    it "errors", ->
      base = parse -> {
        A { fg: "#00FF00", gui: "italic" }
      }
      spec = parse -> {
        A { base.A, gui: "" }
      }


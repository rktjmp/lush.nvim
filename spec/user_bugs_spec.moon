describe "user bugs", ->
  parse = require('lush').parse
  compile = require('lush').compile


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
      assert.matches("gui=NONE", compiled[1])

    it "also handles nil", ->
      spec = -> {
        A { fg: "a_fg", bg: nil, gui: ''}
      }

      -- parsed spec retains empty key
      parsed = parse(spec)
      -- technically not there, nil key-value are "natural" to lua
      assert.equal(nil, parsed.A.bg)

      -- compiler converts to none
      compiled = compile(parsed)
      assert.matches("guibg=NONE", compiled[1])

  describe "key exclusion in compile", ->
    -- https://github.com/rktjmp/lush.nvim/pull/65
    it "can exclude keys", ->
      ast = parse -> {
        A { gui: "italic", blend: 40 }
      }
      compiled = compile(ast, {
        exclude_keys: {"blend"}
      })
      assert.is_not_nil(compiled)
      assert.matches("italic", compiled[1])
      assert.not.matches("blend", compiled[1])

append_hello_plugin = {
  name: "hello plugin",
  make_group: (group_name, group_table, current_rule, entire_spec) ->
    current_rule .. " hello"
  make_link: (group_name, target_group_name, current_rule, entire_spec) ->
    current_rule .. " hello"
}

halting_plugin = {
  name: "halting plugin",
  make_group: (group_name, group_table, current_rule, entire_spec) ->
    current_rule .. " halt", false
  make_link: (group_name, target_group_name, current_rule, entire_spec) ->
    current_rule .. " halt", false
}

configurable_plugin = (config) -> {
  name: "halting plugin",
  make_group: (group_name, group_table, current_rule, entire_spec) ->
    current_rule .. " " .. config.append, false
  make_link: (group_name, target_group_name, current_rule, entire_spec) ->
    current_rule .. " " .. config.append, false
}

describe "compiler plugins", ->
  parse = require('lush.parser')
  compile = require('lush.compiler')
  it "alters rules", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      plugins: {append_hello_plugin}
    })
    assert.is_not_nil(compiled)
    assert.matches("hello$", compiled[1])

  it "can halt the chain", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      plugins: {halting_plugin, append_hello_plugin}
    })
    assert.is_not_nil(compiled)
    assert.matches("halt$", compiled[1])
    assert.not.matches("hello", compiled[1])

  it "can accept configurations for plugins", ->
    ast = parse -> {
      A { gui: "italic", blend: 40 }
    }
    compiled = compile(ast, {
      plugins: {
        configurable_plugin({append: "bart"})
      }
    })
    assert.is_not_nil(compiled)
    assert.matches("bart$", compiled[1])

    compiled = compile(ast, {
      plugins: {
        configurable_plugin({append: "bort"})
      }
    })
    assert.is_not_nil(compiled)
    assert.matches("bort$", compiled[1])

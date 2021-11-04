Q/A
---

#### Lush is too magical, will I get burned?

Meta programming can be scary. It can be confusing to reason with and can be
very infrutrating to debug when something goes wrong "inside the box".

Maybe like all good magic tricks, Lush *looks* a lot more magical than it
really is.

The metaprogramming is really only in the parser, and this is where you write a
very strict subset of instructions (group names, fg, bg, etc).

As long as your spec is valid lua code (correct braces, commas, closing
quotation marks, no spurious characters, etc), there shouldn't be a steep
learning curve or much to actually debug. All you're really doing is writing a
Lua table.

```lua
-- no magic zone
-- anything you do here is just plain old regular lua
local ten = 8 + 2

local spec = lush(function ()
  return {
    -- ~*~ some magic zone ~*~
    -- here we are defining our DSL, some magic required, no magic "leaks" out.

    Normal { fg = "red", bg = hsl(200, 40, 20) },
--  ^      ^                  ^ no magic, just returns a lua table with functions attached
--  |      | just a lua table, no magic
--  | some magic to used to turn function call Normal({...}) into table key Normal = {...}

    CursorLine { fg = Normal.fg.da(10) },
--                    ^ no magic, just a table lookup

    Comment { Normal, fg = "blue" }
--            ^ no magic, just copying one table to another
  }
end)

-- no magic zone
-- returned parsed spec is just a lua table, it has no special magic attached
-- and you can work with it like any other lua table: delete keys, copy values
-- transform values, write to json, etc.

local normal_fg = spec.Normal.fg
--                ^    ^      ^ just a table with functions attached
--                |    | just a table
--                | just a table
```

Similarly in your `color/.vim` file,

```lua
-- no magic zone
local parsed_spec = require('lush_theme.theme') 
--    ^             ^ no magic, just a normal lua module
--    | just a table
lush(parsed_spec)
--   ^ just an if check for table or function and either parses or applies the
--     theme the compiler just iterates over the spec (which is just a table)
--     and interpolates the values into some strings which get sent to vim to
--     interpret.
```

`:Lushify` is also pretty non-magic. It just reads the current buffer, sends it
to the lua interpreter, hoping to get back a parsed lush spec, and then calls
`compile` and `apply` in the background.

#### Why `return ...`?

By returning our theme it acts as a Lua module, which allows us to use it in
other Lua code or other themes.

When we call `lush(lush-spec)` in our `.lua` file, our lush-spec is parsed and
returned as a Lua table, we call this a "parsed-lush-spec". We then `return`
this table at the end of the file.

The parsed-lush-spec can be passed to lush to *apply* the spec (as seen in the
`.vim` file), but by returning the parsed-lush-spec, we can also require the
lush-spec in other Lua code (`require('lush_theme.cool_name')`) and access it's
color values.

#### Why `lua/lush_theme/`?

Lua doesn't have any strict namespacing. Anything in a plugin's `lua/`
directory becomes available as a module in Vim, so it's advised to nest your
theme inside a `lush_theme` folder, providing a namespace for all
lush themes. This is to avoid any collisions between themes and
other modules.

This isn't a strict rule enforced in any way by Lush, simply a recommendation.

#### Is Lush slow?

Short answer: no.

Long answer:

There isn't a noticeable performance impact in using Lush over a raw Vim Script
colorscheme.  The parse and compile stage is generally around 1ms on a quite
aged core i5 and is comparatively dwarfed by the 3ms spent waiting Vim's
interpreter to apply the commands, a penalty which raw Vim Script schemes would
share.

If you noticed a poor performance, you can always export your theme to
Vim Script after using Lush to aid the development process.

*Times measured with libuv's hrtime(), specifically around the parse, compile
and apply calls. There may be a few extra nanoseconds not recorded between
calling in and out of functions, as well as the initial file load time
(which Vim Script would also incur).*

```
Parse:   286300  ns  0.2863 ms -- resolve lush-spec into concrete values
Compile: 671900  ns  0.6719 ms -- convert concrete spec into vimscript commands
Apply:   3134300 ns  3.1343 ms -- pass to Vim Script interpreter (iterate array and call "nvim_command", "nvim_exec" performance is identical)
Total:   4092500 ns  4.0925 ms

Parse:   373500  ns  0.3735 ms
Compile: 973400  ns  0.9734 ms
Apply:   3442400 ns  3.4424 ms
Total:   4789300 ns  4.7893 ms

Parse:   388700  ns  0.3887 ms
Compile: 705500  ns  0.7055 ms
Apply:   3446900 ns  3.4469 ms
Total:   4541100 ns  4.5411 ms

Parse:   299400  ns  0.2994 ms
Compile: 814600  ns  0.8146 ms
Apply:   3065300 ns  3.0653 ms
Total:   4179300 ns  4.1793 ms
```

See also [issue #19](https://github.com/rktjmp/lush.nvim/issues/19), where
1000, 2000 and 4000 rule specs were tested. Vim Script is stll consistently the
bottleneck.

Note that a 1000 rule spec is likely pretty unsual. There are only about 150
base groups provided by Neovim and most plugins only provide another 5-10 (or
less).

A 4k rule spec would probably mean you're loading an enourmous number of
plugins, at which point your load times are probably also already enormous.

Also as per the issue, since Vim Script is such a huge bottleneck, you may find
similarly sized colorschemes actually load *faster* via Lush because any maths
and manipulation is done via Lua instead.

```
1k rules
--------
parse time:    4095342 ns,  4.095342 ms
compile time:   863515 ns,  0.863515 ms
apply time:   13150290 ns, 13.150290 ms

2k rules
--------
parse time:    8310824 ns,  8.310824 ms
compile time:  1791501 ns,  1.791501 ms
apply time:   34649903 ns, 34.649903 ms

4k rules
--------
parse time:   15170685 ns, 15.170685 ms
compile time:  6865722 ns,  6.865722 ms
apply time:   82630480 ns, 82.630480 ms
```

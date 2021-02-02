Future ideas
============

Theme Inheritance
-----------------

This would give you the ability to require someone else's theme as a base to
yours.

Imagine you really like a theme, but wish the background was a bit different,
you could define your lush-spec with that theme as base/parent and just change
the groups you want.

I have a draft of this written but was unsure how useful it would really be as
a feature and if it was worth the work hours. Perhaps if Lush were popular this
more sense.


Global HSL Shifting / Contrast Shifting?
----------------------------------------

Unsure how useful this would be in the real world, but switching between some
machines can render some colourschemes differently, because their screens
or terminals are different.

The idea would be you could set a global shift on HSL to effect all colours
that are pushed through it.

In actuality, I think what I *really* want is a contrast scale, which isn't as
simple as simply "make it all brighter" or "make it all bluer".

**Automatic Property Inference**

Would allow for syntax like:

```lua
-- automatically infer appropriate key (Normal.fg)
CursorLine { fg = Normal, bg = Visual }
```

Most of this code is actually already present, but the ability to write
`fg = Normal` tends to encourage `fg = Normal.ro(...)` at a later time,
is an invalid operation.

Without a uniform solution to this, I'm reticent to "muddy" the API.

For now, you must write `fg = Normal.fg`.

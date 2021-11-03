-- check we have the expected imports
assert(type(lush) == "table")
assert(type(run) == "function")
assert(type(branch) == "function")
assert(type(overwrite) == "function")
assert(type(patchwrite) == "function")
assert(type(viml) == "function")
assert(type(vim_compatible) == "function")
assert(type(lua) == "function")
assert(type(prepend) == "function")
assert(type(append) == "function")
assert(type(contrib) == "table")
-- can still access normal stuff
assert(type(vim) == "table")

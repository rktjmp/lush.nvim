-- check we have the expected imports
assert(type(lush) == "table")
assert(type(export) == "function")
assert(type(overwrite) == "function")
assert(type(patchwrite) == "function")
assert(type(viml) == "function")
assert(type(lua) == "function")
assert(type(prepend) == "function")
assert(type(append) == "function")
-- can still access normal stuff
assert(type(vim) == "table")

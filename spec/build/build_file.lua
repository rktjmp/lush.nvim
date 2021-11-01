-- check we have the expected imports
assert(type(lush) == "table")
assert(type(export) == "function")
assert(type(overwrite) == "function")
assert(type(patchwrite) == "function")
assert(type(viml) == "function")
assert(type(prepend_lines) == "function")
assert(type(append_lines) == "function")
-- can still access normal stuff
assert(type(vim) == "table")

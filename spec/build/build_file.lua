-- check we have the expected imports
assert(type(lush) == "table")
assert(type(export) == "function")
assert(type(overwrite) == "function")
assert(type(patchwrite) == "function")
assert(type(viml) == "function")
-- can still access normal stuff
assert(type(vim) == "table")

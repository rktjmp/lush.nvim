local MAJOR, REV = "scm", "-1"
rockspec_format = "3.0"
package = "lush.nvim"
version = MAJOR .. REV

description = {
	summary = "Define Neovim themes as a DSL in lua, with real-time feedback.",
	labels = { "neovim" },
	detailed = [[
    Lush is a colorscheme creation aid, written in Lua, for Neovim.
   ]],
	homepage = "https://github.com/rktjmp/lush.nvim",
	license = "MIT/X11",
}

dependencies = {
	"lua >= 5.1, < 5.4",
}

source = {
	url = "http://github.com/rktjmp/lush.nvim/archive/v" .. MAJOR .. ".zip",
	dir = "lush.nvim-" .. MAJOR,
}

if MAJOR == "scm" then
	source = {
		url = "git://github.com/rktjmp/lush.nvim",
	}
end

build = {
	type = "builtin",
}
test_dependencies = {
	"moonscript",
}

let s:lush_root = expand('<sfile>:p:h') . "/../"
command! LushRunQuickstart :call <sid>run_temp(s:lush_root, "lush_quickstart.lua")
command! LushRunTutorial :call <sid>run_temp(s:lush_root, "lush_tutorial.lua")
command! Lushify :lua require('lush').ify()
command! LushImport :lua require('lush').import()

function! s:run_temp(lush_root, filename)
lua << EOF
  local lush_root = vim.fn.eval("a:lush_root")
  local filename = vim.fn.eval("a:filename")
  -- generate a temp file name
  local temp = vim.fn.tempname()

  -- find source
  local file = lush_root .. "/examples/" .. filename

  -- open temp
  local success = vim.loop.fs_copyfile(file, temp)
  if success then
    vim.cmd("edit " .. temp)
    vim.cmd("set ft=lua")
  else
    print("Vim could not create temporary file, please copy " ..
          "examples/" .. filename .. " to a new directory and open manually")
  end
EOF
endfunction

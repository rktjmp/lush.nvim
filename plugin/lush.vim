
command! LushRunQuickstart :call <sid>run_temp("lush_quickstart.lua")
command! LushRunTutorial :call <sid>run_temp("lush_tutorial.lua")
command! Lushify :lua require('lush').ify()

function! s:run_temp(filename)
lua << EOF
  local filename = vim.fn.eval("a:filename")
  -- generate a temp file name
  local temp = vim.fn.tempname()

  -- find source
  local from_dir = vim.fn.expand('<sfile>:p:h')
  local file = from_dir .. "/examples/" .. filename

  -- open temp
  local success = vim.loop.fs_copyfile(file, temp)
  if success then
    vim.cmd("edit " .. temp)
  else
    print("Could not create temporary file, please copy " ..
          "examples/" .. filename .. " to a new directory and open manually")
  end
EOF
endfunction

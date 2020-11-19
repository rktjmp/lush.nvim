
let s:lush_folder = expand('<sfile>:p:h')
let s:quick_start = s:lush_folder.'/../examples/lush_quickstart.lua' 
let s:tutorial_start = s:lush_folder.'/../examples/lush_tutorial.lua' 

command! LushRunQuickstart :execute 'edit' s:quick_start
command! LushRunTutorial :execute 'edit' s:tutorial_start
command! Lushify :lua require('lush').ify()

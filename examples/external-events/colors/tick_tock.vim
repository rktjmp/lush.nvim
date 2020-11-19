" You probably always want to set this in your vim file
set background=dark
let g:colors_name="tick_tock"

" By setting our module to nil, we clear lua's cache,
" which means the require ahead will *always* occur.
"
" This isn't strictly required but it can be a useful trick if you are
" incrementally editing your confit a lot and want to be sure your themes
" changes are being picked up without restarting neovim.
"
" Note if you're working in on your theme and have lush.ify'd the buffer,
" your changes will be applied with our without the following line.
lua package.loaded['lush_theme.tick_tock'] = nil

lua << EOF
  local bang
  bang = function()
    -- clear lua's cache so our module gets to run again
    package.loaded['lush_theme.tick_tock'] = nil

    -- pass our theme to lush to apply
    require('lush')(require('lush_theme.tick_tock'))

    -- setup re-call
    vim.defer_fn(bang, 500)
  end
  vim.defer_fn(bang, 500)
EOF


" configure lightline somewhere, traditionally *NOT* in the colors file
" lightline is kind of tempermental in terms of load ordering.
" if you're loading this theme after opening neovim, you may have to
" call lightline#disable() then call lightline#enable() to make
" the theme be applied initially, or try lightline#colorscheme()
let g:lightline = { 'colorscheme': 'lightline_two_files' }

" You probably always want to set this in your vim file
set background=dark
let g:colors_name="lightline_two_files"

" By setting our module to nil, we clear lua's cache,
" which means the require ahead will *always* occur.
"
" This isn't strictly required but it can be a useful trick if you are
" incrementally editing your confit a lot and want to be sure your themes
" changes are being picked up without restarting neovim.
"
" Note if you're working in on your theme and have lush.ify'd the buffer,
" your changes will be applied with our without the following line.
lua package.loaded['lush_theme.lightline_two_files'] = nil

" include our theme file and pass it to lush to apply
" load the main theme
lua require('lush')(require('lush_theme.lightline_two_files'))
" load our lua code which defines the lightline theme
" note that this isn't a lush theme or lush-spec, it simply loads
" the lush spec as a module (see file)
lua require('lush_theme.lightline_two_files_lightline')


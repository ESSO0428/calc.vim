if exists("g:loaded_calc")
  finish
endif

if !hlexists("calcResult")
  highlight! link calcResult Type
endif

command! -nargs=0 Calculator silent! call calc#open()

let g:loaded_calc = 69
